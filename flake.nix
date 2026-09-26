{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    xremap-flake.url = "github:xremap/nix-flake";
    wlctl.url = "github:aashish-thapa/wlctl";
    nix-minecraft.url = "github:Infinidoge/nix-minecraft";
    soulbrainz.url = "github:retr0mouse/soulbrainz";
    noctalia-greeter.url = "github:noctalia-dev/noctalia-greeter";
    looking-glass-src = {
      url = "git+https://github.com/gnif/LookingGlass?rev=236efcb155f952f5d7d9fcd5891a3060ad254e68&submodules=1";
      flake = false;
    };
  };

  outputs = inputs @ {
    nixpkgs,
    home-manager,
    ...
  }: let
    roles = {
      clancy = {
        systemModule = ./system/roles/clancy;
        userModule = ./user/roles/clancy;
      };

      nico = {
        systemModule = ./system/roles/nico;
        userModule = ./user/roles/nico;
      };
    };

    machines = {
      "asus-ga503" = {
        system = "x86_64-linux";
        systemModule = ./system/machines/asus-ga503;
        roleSystemModules.clancy = ./system/machines/asus-ga503/clancy.nix;
        roleUserModules.clancy = ./user/machines/asus-ga503/clancy.nix;
      };

      "msi-gp62m-7rdx" = {
        system = "x86_64-linux";
        systemModule = ./system/machines/msi-gp62m-7rdx;
        roleSystemModules.nico = ./system/machines/msi-gp62m-7rdx/nico.nix;
      };
    };

    # A deployment assigns one transferable role to one physical machine.
    # Staged replacements can be added alongside the active role with
    # activateIdentity = false and a temporary deployment name.
    deployments = {
      clancy = {
        role = "clancy";
        machine = "asus-ga503";
        username = "reisdro";
      };

      nico = {
        role = "nico";
        machine = "msi-gp62m-7rdx";
        username = "reisdro";
      };
    };

    activeIdentityDeploymentsFor = roleName:
      nixpkgs.lib.filterAttrs (
        _deploymentName: deployment:
          deployment.role == roleName && (deployment.activateIdentity or true)
      )
      deployments;

    duplicateIdentityRoles = nixpkgs.lib.filter (
      roleName:
        builtins.length (builtins.attrNames (activeIdentityDeploymentsFor roleName)) > 1
    ) (builtins.attrNames roles);

    mkDeployment = deploymentName: deployment: let
      role = roles.${deployment.role};
      machine = machines.${deployment.machine};
      roleName = deployment.role;
      machineName = deployment.machine;
      username = deployment.username;
      roleSystemModule =
        nixpkgs.lib.attrByPath [roleName] null (machine.roleSystemModules or {});
      roleUserModule =
        nixpkgs.lib.attrByPath [roleName] null (machine.roleUserModules or {});
      userModules =
        [
          ./user/common.nix
          role.userModule
        ]
        ++ nixpkgs.lib.optional (roleUserModule != null) roleUserModule;
    in
      nixpkgs.lib.nixosSystem {
        specialArgs = {
          inherit inputs machineName roleName username;
        };

        modules =
          [
            {nixpkgs.hostPlatform = machine.system;}
            ./system/modules/deployment.nix
            ./system/common.nix
            role.systemModule
            machine.systemModule
          ]
          ++ nixpkgs.lib.optional (roleSystemModule != null) roleSystemModule
          ++ [
            home-manager.nixosModules.home-manager

            {
              networking.hostName = deployment.hostName or deploymentName;

              dotfiles.deployment = {
                role = roleName;
                machine = machineName;
                activateIdentity = deployment.activateIdentity or true;
              };

              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.backupFileExtension = "backup";

              home-manager.extraSpecialArgs = {
                inherit inputs machineName roleName username;
              };

              home-manager.users.${username}.imports = userModules;
            }
          ];
      };
  in {
    nixosConfigurations =
      if duplicateIdentityRoles == []
      then nixpkgs.lib.mapAttrs mkDeployment deployments
      else
        throw ''
          Multiple active deployments claim the same role identity: ${
            nixpkgs.lib.concatStringsSep ", " duplicateIdentityRoles
          }. Set activateIdentity = false on staged replacements.
        '';
  };
}

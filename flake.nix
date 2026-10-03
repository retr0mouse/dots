{
  nixConfig = {
    extra-substituters = [
      "https://nixos-raspberrypi.cachix.org"
    ];
    extra-trusted-public-keys = [
      "nixos-raspberrypi.cachix.org-1:4iMO9LXa8BqhU+Rpg6LQKiGa2lsNh/j2oiYLNOQ5sPI="
    ];
  };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";

    # The Raspberry Pi 5 boot support and current Plasma Bigscreen package
    # are newer than the package set used by the existing deployments.
    nixpkgs-tv.url = "github:nixos/nixpkgs/nixos-unstable";

    # Declarative Raspberry Pi firmware, bootloader and vendor kernel stack.
    # Keep this pinned to a release so a future input update cannot silently
    # replace the kernel used by the TV image.
    nixos-raspberrypi.url = "github:nvmd/nixos-raspberrypi/v1.20260801.0";

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager-tv = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs-tv";
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

      tv = {
        systemModule = ./system/roles/tv;
        userModule = ./user/roles/tv;
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

      "raspberry-pi-5" = {
        system = "aarch64-linux";
        nixpkgsInput = inputs.nixpkgs-tv;
        homeManagerInput = inputs.home-manager-tv;
        systemModule = ./system/machines/raspberry-pi-5;
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

      tv = {
        role = "tv";
        machine = "raspberry-pi-5";
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
      deploymentNixpkgs = machine.nixpkgsInput or nixpkgs;
      deploymentHomeManager = machine.homeManagerInput or home-manager;
      enableHomeManager = machine.enableHomeManager or (role ? userModule);
      roleSystemModule =
        nixpkgs.lib.attrByPath [roleName] null (machine.roleSystemModules or {});
      roleUserModule =
        nixpkgs.lib.attrByPath [roleName] null (machine.roleUserModules or {});
      userModules = nixpkgs.lib.optionals enableHomeManager (
        [
          ./user/common.nix
          role.userModule
        ]
        ++ nixpkgs.lib.optional (roleUserModule != null) roleUserModule
      );
    in
      deploymentNixpkgs.lib.nixosSystem {
        specialArgs = {
          inherit inputs machineName roleName username;
          nixos-raspberrypi = inputs.nixos-raspberrypi;
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
          ++ nixpkgs.lib.optionals enableHomeManager [
            deploymentHomeManager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.backupFileExtension = "backup";

              home-manager.extraSpecialArgs = {
                inherit inputs machineName roleName username;
              };

              home-manager.users.${username}.imports = userModules;
            }
          ]
          ++ [
            {
              networking.hostName = deployment.hostName or deploymentName;

              dotfiles.deployment = {
                role = roleName;
                machine = machineName;
                activateIdentity = deployment.activateIdentity or true;
              };
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

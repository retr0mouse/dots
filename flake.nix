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
    noctalia-greeter,
    ...
  }: let
    system = "x86_64-linux";
    mkDesktopHost = {
      hostName,
      username,
    }:
      nixpkgs.lib.nixosSystem {
        inherit system;

        specialArgs = {
          inherit inputs username;
        };

        modules = [
          ./system/hosts/${hostName}/configuration.nix

          home-manager.nixosModules.home-manager
          noctalia-greeter.nixosModules.default

          {
            nixpkgs.overlays = [
              (final: prev: {
                hyprmoncfg = final.callPackage ./packages/hyprmoncfg.nix {};
              })
            ];

            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.backupFileExtension = "backup";

            home-manager.extraSpecialArgs = {
              inherit inputs username;
            };

            home-manager.users.${username} = import ./user/home.nix;
          }
        ];
      };
    mkServerHost = {
      hostName,
      username,
    }:
      nixpkgs.lib.nixosSystem {
        inherit system;

        specialArgs = {
          inherit inputs username;
        };

        modules = [
          ./system/hosts/${hostName}/configuration.nix
          home-manager.nixosModules.home-manager

          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.backupFileExtension = "backup";

            home-manager.extraSpecialArgs = {
              inherit inputs username;
            };

            home-manager.users.${username} = import ./user/home-server.nix;
          }
        ];
      };
  in {
    nixosConfigurations = {
      clancy = mkDesktopHost {
        hostName = "clancy";
        username = "reisdro";
      };
      nico = mkServerHost {
        hostName = "nico";
        username = "reisdro";
      };
    };
  };
}

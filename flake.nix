{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";

    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

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
  };

  outputs = inputs @ {
    self,
    nixpkgs,
    home-manager,
    wlctl,
    nix-minecraft,
    soulbrainz,
    nixpkgs-unstable,
    noctalia-greeter,
    ...
  }: let
    system = "x86_64-linux";
    user = "reisdro";
    mkDesktopHost = hostname:
      nixpkgs.lib.nixosSystem {
        inherit system;

        specialArgs = {
          inherit inputs user;
        };

        modules = [
          ./system/hosts/${hostname}/configuration.nix

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
              inherit inputs user;
            };

            home-manager.users.${user} = import ./user/home.nix;
          }
        ];
      };
    mkServerHost = hostname:
      nixpkgs.lib.nixosSystem {
        inherit system;

        specialArgs = {
          inherit inputs user;
        };

        modules = [
          ./system/hosts/${hostname}/configuration.nix
          home-manager.nixosModules.home-manager
          nix-minecraft.nixosModules.minecraft-servers
          soulbrainz.nixosModules.default

          {
            services.soulbrainz = {
              enable = true;
            };
          }

          {
            nixpkgs.overlays = [
              inputs.nix-minecraft.overlay
            ];
          }

          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.backupFileExtension = "backup";

            home-manager.extraSpecialArgs = {
              inherit inputs user;
            };

            home-manager.users.${user} = import ./user/home-server.nix;
          }
        ];
      };
  in {
    nixosConfigurations = {
      clancy = mkDesktopHost "clancy";
      nico = mkServerHost "nico";
    };
  };
}

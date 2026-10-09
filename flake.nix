{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
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
  }: {
    formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.alejandra;

    nixosConfigurations = {
      clancy = nixpkgs.lib.nixosSystem {
        specialArgs = {
          inherit inputs;
          username = "reisdro";
        };

        modules = [
          {nixpkgs.hostPlatform = "x86_64-linux";}
          home-manager.nixosModules.home-manager
          ./hosts/clancy
        ];
      };

      nico = nixpkgs.lib.nixosSystem {
        specialArgs = {
          inherit inputs;
          username = "reisdro";
        };

        modules = [
          {nixpkgs.hostPlatform = "x86_64-linux";}
          home-manager.nixosModules.home-manager
          ./hosts/nico
        ];
      };
    };
  };
}

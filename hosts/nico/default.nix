{
  config,
  inputs,
  username,
  ...
}: {
  imports = [
    ../../modules/nixos/common.nix
    inputs.sops-nix.nixosModules.sops

    ./server.nix
    ./applications.nix
    ./minecraft.nix
    ./monitoring.nix
    ./networking.nix

    ../../modules/nixos/uefi-systemd-boot.nix
    ./hardware-configuration.nix
    ./hardware.nix
    ./hardware-policy.nix
  ];

  networking.hostName = "nico";

  assertions = [
    {
      assertion = builtins.hasAttr "/data" config.fileSystems;
      message = "Nico requires a /data filesystem for application storage.";
    }
  ];

  # SOPS converts this existing SSH host identity into an age identity.
  # The key is stateful and must never be copied into the Nix store.
  sops.age.sshKeyPaths = ["/etc/ssh/ssh_host_ed25519_key"];

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "backup";
    extraSpecialArgs = {inherit inputs username;};
    users.${username}.imports = [
      ../../modules/home/common.nix
      ./home.nix
    ];
  };
}

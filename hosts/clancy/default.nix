{
  inputs,
  username,
  ...
}: {
  imports = [
    ../../modules/nixos/common.nix
    inputs.sops-nix.nixosModules.sops

    ./networking.nix
    ./desktop.nix

    ../../modules/nixos/uefi-systemd-boot.nix
    ./hardware-configuration.nix
    inputs.nixos-hardware.nixosModules.asus-zephyrus-ga503
    ./hardware.nix

    ./vfio.nix
    ./looking-glass.nix
    ./graphics.nix
  ];

  networking.hostName = "clancy";

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
      ./home-hardware.nix
    ];
  };
}

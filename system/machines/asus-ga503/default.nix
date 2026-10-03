{inputs, ...}: {
  imports = [
    ../../features/uefi-systemd-boot.nix
    ./hardware-configuration.nix
    inputs.nixos-hardware.nixosModules.asus-zephyrus-ga503
  ];

  # Work around the AMDGPU custom brightness curve wrapping to zero near 100%.
  boot.kernelParams = ["amdgpu.dcdebugmask=0x40000"];

  # Let this machine assemble native AArch64 NixOS images. Runtime packages
  # are substituted from caches; QEMU is only needed for small image-building
  # steps that must execute AArch64 programs.
  boot.binfmt.emulatedSystems = ["aarch64-linux"];

  nix.settings = {
    extra-substituters = [
      "https://nixos-raspberrypi.cachix.org"
    ];
    extra-trusted-public-keys = [
      "nixos-raspberrypi.cachix.org-1:4iMO9LXa8BqhU+Rpg6LQKiGa2lsNh/j2oiYLNOQ5sPI="
    ];
  };

  services.asusd.enable = true;
  services.power-profiles-daemon.enable = true;
  services.logind.settings.Login.HandleLidSwitchExternalPower = "ignore";

  dotfiles.hardware = {
    battery = true;
    backlight = true;
    powerProfiles = true;
    integratedGpu = true;
    discreteGpu = true;
  };

  # This follows the installation, not the logical role assigned to it.
  system.stateVersion = "25.11";
}

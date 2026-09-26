{inputs, ...}: {
  imports = [
    ../../features/uefi-systemd-boot.nix
    ./hardware-configuration.nix
    inputs.nixos-hardware.nixosModules.asus-zephyrus-ga503
  ];

  # Work around the AMDGPU custom brightness curve wrapping to zero near 100%.
  boot.kernelParams = ["amdgpu.dcdebugmask=0x40000"];

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

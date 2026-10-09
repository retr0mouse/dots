{...}: {
  # Work around the AMDGPU custom brightness curve wrapping to zero near 100%.
  boot.kernelParams = ["amdgpu.dcdebugmask=0x40000"];

  services.asusd.enable = true;
  services.power-profiles-daemon.enable = true;
  services.logind.settings.Login.HandleLidSwitchExternalPower = "ignore";

  # Compatibility baseline of this existing installation; do not bump casually.
  system.stateVersion = "25.11";
}

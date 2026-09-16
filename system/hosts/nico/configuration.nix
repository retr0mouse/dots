{
  config,
  pkgs,
  ...
}: {
  imports = [
    ../../modules/server.nix
    ./hardware-configuration.nix
    ./networking.nix
    ./applications.nix
    ./minecraft.nix
    ./monitoring.nix
  ];

  zramSwap.enable = true;

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  services.xserver.videoDrivers = ["nvidia"];

  hardware.nvidia = {
    modesetting.enable = true;
    open = false;
    package = config.boot.kernelPackages.nvidiaPackages.legacy_580;
  };

  boot.blacklistedKernelModules = ["nouveau"];

  services.logind.settings.Login = {
    HandleLidSwitch = "ignore";
    HandleLidSwitchDocked = "ignore";
    HandleLidSwitchExternalPower = "ignore";
  };

  systemd.sleep.settings.Sleep = {
    AllowSuspend = "no";
    AllowHibernation = "no";
    AllowHybridSleep = "no";
  };

  services.journald.extraConfig = ''
    SystemMaxUse=500M
  '';

  environment.systemPackages = [pkgs.kitty.terminfo];

  system.stateVersion = "25.11";
}

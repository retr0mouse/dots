{config, ...}: {
  imports = [
    ../../features/uefi-systemd-boot.nix
    ./hardware-configuration.nix
  ];

  # Physical disk currently providing the stable /data service path.
  fileSystems."/data" = {
    device = "/dev/disk/by-uuid/efee3c35-c283-4091-9a72-5df4cfcb2412";
    fsType = "ext4";
    options = [
      "noatime"
      "nofail"
      "x-systemd.device-timeout=5s"
    ];
  };

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

  dotfiles.hardware.videoAcceleration = "nvenc";
  dotfiles.hardware.lanInterface = "enp3s0";

  boot.blacklistedKernelModules = ["nouveau"];

  # This follows the installation, not the logical role assigned to it.
  system.stateVersion = "25.11";
}

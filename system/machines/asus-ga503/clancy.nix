{
  config,
  lib,
  pkgs,
  ...
}: {
  # Hardware integration used when this machine provides the Clancy role.
  imports = [
    ./vfio.nix
    ./looking-glass.nix
  ];

  services.libinput = {
    enable = true;
    touchpad.naturalScrolling = true;
  };

  services.xserver = {
    enable = true;
    videoDrivers = ["amdgpu" "nvidia"];
  };

  services.udev.extraRules = ''
    KERNEL=="card*", \
    KERNELS=="0000:06:00.0", \
    SUBSYSTEM=="drm", \
    SUBSYSTEMS=="pci", \
    SYMLINK+="dri/amd-igpu"
  '';

  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = true;
    powerManagement.finegrained = true;

    open = true;
    nvidiaSettings = true;

    package = config.boot.kernelPackages.nvidiaPackages.stable;

    prime = {
      amdgpuBusId = lib.mkForce "PCI:6:0:0";
      nvidiaBusId = "PCI:1:0:0";

      offload = {
        enable = true;
        enableOffloadCmd = true;
      };
    };
  };

  hardware.graphics.extraPackages = with pkgs; [
    mesa
  ];
}

{
  config,
  lib,
  pkgs,
  inputs,
  username,
  ...
}: {
  imports = [
    ../../modules/desktop.nix
    ./hardware-configuration.nix
    ./vfio.nix
    ./looking-glass.nix
    inputs.nixos-hardware.nixosModules.asus-zephyrus-ga503
  ];

  home-manager.users.${username}.imports = [../../../user/hosts/clancy.nix];

  networking.hostName = "clancy";
  networking.wg-quick.interfaces = {
    wg0 = {
      address = ["10.10.0.6/32"];
      dns = ["10.10.0.1"];
      privateKeyFile = "/etc/wireguard/privatekey";

      peers = [
        {
          publicKey = "H/aACRc0usVuOYhIQrD4hYQKU7xePHWEwkX91Wm/yFI=";
          allowedIPs = ["10.10.0.0/24" "192.168.0.0/24"];
          endpoint = "voldsoy.duckdns.org:51820";
          persistentKeepalive = 25;
        }
      ];
    };
  };
  systemd.services.wg-quick-wg0 = {
    wants = ["network-online.target"];
    after = ["network-online.target"];

    serviceConfig = {
      Restart = "on-failure";
      RestartSec = 5;
    };
  };

  services.asusd.enable = true;
  services.power-profiles-daemon.enable = true;
  services.logind.settings.Login.HandleLidSwitchExternalPower = "ignore";

  services.libinput = {
    enable = true;
    touchpad.naturalScrolling = true;
  };

  services.xserver.enable = true;

  services.udev.extraRules = ''
    KERNEL=="card*", \
    KERNELS=="0000:06:00.0", \
    SUBSYSTEM=="drm", \
    SUBSYSTEMS=="pci", \
    SYMLINK+="dri/amd-igpu"
  '';

  services.xserver.videoDrivers = ["amdgpu" "nvidia"];

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

  system.stateVersion = "25.11";
}

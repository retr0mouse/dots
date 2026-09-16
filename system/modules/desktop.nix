{
  inputs,
  lib,
  pkgs,
  username,
  ...
}: {
  imports = [
    ./common.nix
    inputs.xremap-flake.nixosModules.default
  ];

  # Input / Key remapping
  services.xremap = {
    enable = true;
    serviceMode = "user";
    withWlroots = true;
    userName = username;

    config = {
      virtual_modifiers = ["CapsLock"];
      keymap = [
        {
          remap = {
            "CapsLock-i" = "Up";
            "CapsLock-j" = "Left";
            "CapsLock-k" = "Down";
            "CapsLock-l" = "Right";

            "CapsLock-m" = "Home";
            "CapsLock-dot" = "End";

            "CapsLock-u" = "C-Left";
            "CapsLock-o" = "C-Right";
          };
        }
      ];
    };
  };

  # Boot splash
  boot = {
    plymouth = {
      enable = true;
      theme = "breeze";
    };

    kernelParams = ["splash"];
  };

  # Core desktop services
  services = {
    upower.enable = true;
    pcscd.enable = true;
    gvfs.enable = true;
    udisks2.enable = true;
  };

  security = {
    polkit.enable = true;
    rtkit.enable = true;
  };

  # NetworkManager with a wpa_supplicant Wi-Fi backend
  networking = {
    networkmanager.enable = true;
    networkmanager.wifi.backend = "wpa_supplicant";
  };

  systemd.services.NetworkManager-wait-online.enable = false;

  # Display Manager
  programs.noctalia-greeter = {
    enable = true;
    settings = {
      cursor = {
        theme = "Bibata-Modern-Classic";
        size = 24;
        path = "${pkgs.bibata-cursors}/share/icons";
      };
    };
  };

  programs = {
    xwayland.enable = true;
    hyprland = {
      enable = true;
      withUWSM = true;
    };

    steam.enable = true;

    gamescope.enable = true;
  };

  # Bluetooth
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;

  # Audio
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    wireplumber.enable = true;
  };

  # Fonts
  fonts.packages = with pkgs; [
    nerd-fonts.fira-code
    nerd-fonts.iosevka
    font-awesome
    material-design-icons
  ];

  # Keyboard layout (X11 fallback — keep in sync with Hyprland kb_layout)
  services.xserver.xkb = {
    layout = "ee(us),ru";
    options = "grp:ctrl_space_toggle";
  };

  # XDG portals
  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
      xdg-desktop-portal-hyprland
    ];
  };

  # User
  users.users.${username}.extraGroups = lib.mkAfter [
    "input"
    "networkmanager"
    "video"
    "render"
  ];
}

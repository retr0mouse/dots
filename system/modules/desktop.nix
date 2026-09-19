{
  inputs,
  lib,
  pkgs,
  username,
  ...
}: let
  plymouthTheme = pkgs.runCommand "waybar-plymouth-theme" {} ''
    themeDir="$out/share/plymouth/themes/waybar"
    mkdir -p "$themeDir"
    cp ${./plymouth/waybar.script} "$themeDir/waybar.script"
    substitute ${./plymouth/waybar.plymouth} "$themeDir/waybar.plymouth" \
      --replace-fail '@out@' "$out"
  '';
in {
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
    # Keep listening for keyboards connected after xremap starts.
    watch = true;

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

  # The upstream NixOS module does not restart its user service. Retry forever
  # so transient input-device or session disruptions cannot leave remapping off.
  systemd.user.services.xremap = {
    partOf = ["graphical-session.target"];
    after = ["graphical-session.target"];
    startLimitIntervalSec = 0;
    serviceConfig = {
      Restart = "always";
      RestartSec = "2s";
    };
  };

  # Boot splash
  boot = {
    plymouth = {
      enable = true;
      theme = "waybar";
      themePackages = [plymouthTheme];
      font = "${pkgs.nerd-fonts.iosevka}/share/fonts/truetype/NerdFonts/Iosevka/IosevkaNerdFont-Regular.ttf";
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
      appearance = {
        scheme = "Synced";
        theme_mode = "dark";
        password_style = "default";
        hide_logo = true;
        power_buttons_position = "bottom-right";
        scheme_selector_position = "hidden";
        corner_radius_scale = 0.0;
        font_family = "Iosevka Nerd Font";

        palette = {
          primary = "#98a87c";
          on_primary = "#101211";
          secondary = "#7f9f9f";
          on_secondary = "#101211";
          tertiary = "#a8b98c";
          on_tertiary = "#101211";
          error = "#d08770";
          on_error = "#101211";
          surface = "#101211";
          on_surface = "#c5c8c5";
          surface_variant = "#1a1d1b";
          on_surface_variant = "#7f9f9f";
          outline = "#303630";
          shadow = "#101211";
          hover = "#7f9f9f";
          on_hover = "#101211";
        };

        wallpaper = {
          path = "color:#101211";
          fill_mode = "crop";
          fill_color = "#101211";
        };
      };

      cursor = {
        theme = "Bibata-Modern-Classic";
        size = 24;
        path = "${pkgs.bibata-cursors}/share/icons";
      };

      keyboard = {
        layout = "ee(us),ru";
        options = "grp:ctrl_space_toggle";
        numlock = true;
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

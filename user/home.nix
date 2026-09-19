{pkgs, ...}: {
  imports = [
    ./common.nix
    ./modules/hyprland
    ./modules/waybar
    ./modules/rofi
    ./modules/session-controls
    ./modules/swaync
    ./modules/terminal-tools
    ./modules/kitty.nix
    ./modules/pwvucontrol
    ./modules/brave.nix
    ./programs.nix
    ./scripts.nix
  ];

  programs.zsh.shellAliases.slip = "hyprlock & sleep 0.5 && systemctl suspend";

  services.hyprpolkitagent.enable = true;

  systemd.user.services.waybar = {
    Unit = {
      Description = "Waybar";
      After = ["graphical-session.target"];
      PartOf = ["graphical-session.target"];
    };

    Service = {
      ExecStart = "${pkgs.waybar}/bin/waybar";
      Restart = "on-failure";
    };

    Install = {
      WantedBy = ["graphical-session.target"];
    };
  };

  systemd.user.services.swaync = {
    Unit = {
      Description = "Sway Notification Center";
      After = ["graphical-session.target"];
      PartOf = ["graphical-session.target"];
    };

    Service = {
      ExecStart = "${pkgs.swaynotificationcenter}/bin/swaync";
      Restart = "on-failure";
    };

    Install = {
      WantedBy = ["graphical-session.target"];
    };
  };

  systemd.user.services.cliphist-text = {
    Unit = {
      Description = "Clipboard history text watcher";
      After = ["graphical-session.target"];
      PartOf = ["graphical-session.target"];
    };

    Service = {
      ExecStart = "${pkgs.wl-clipboard}/bin/wl-paste --type text --watch ${pkgs.cliphist}/bin/cliphist store";
      Restart = "on-failure";
    };

    Install = {
      WantedBy = ["graphical-session.target"];
    };
  };

  systemd.user.services.cliphist-image = {
    Unit = {
      Description = "Clipboard history image watcher";
      After = ["graphical-session.target"];
      PartOf = ["graphical-session.target"];
    };

    Service = {
      ExecStart = "${pkgs.wl-clipboard}/bin/wl-paste --type image --watch ${pkgs.cliphist}/bin/cliphist store";
      Restart = "on-failure";
    };

    Install = {
      WantedBy = ["graphical-session.target"];
    };
  };

  systemd.user.services.hyprmoncfgd = {
    Unit = {
      Description = "hyprmoncfg monitor configuration daemon";
      After = ["graphical-session.target"];
      PartOf = ["graphical-session.target"];
    };

    Service = {
      ExecStart = "${pkgs.hyprmoncfg}/bin/hyprmoncfgd";
      Restart = "on-failure";
    };

    Install = {
      WantedBy = ["graphical-session.target"];
    };
  };

  home.stateVersion = "24.11"; # First-deploy version — do not change.

  wayland.windowManager.hyprland.systemd.enable = false;
  gtk = {
    enable = true;
    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };
  };

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  home.pointerCursor = {
    gtk.enable = true;
    x11.enable = true;
    package = pkgs.bibata-cursors;
    name = "Bibata-Modern-Classic";
    size = 24;
  };

  home.file = {
  };

  # Default apps
  xdg.mimeApps = {
    enable = true;

    defaultApplications = {
      "text/html" = "brave.desktop";
      "x-scheme-handler/http" = "brave.desktop";
      "x-scheme-handler/https" = "brave.desktop";
      "x-scheme-handler/about" = "brave.desktop";
      "x-scheme-handler/unknown" = "brave.desktop";
    };
  };

  home.sessionVariables = {
    NIXOS_OZONE_WL = "1"; # Force Wayland for electron apps

    #Wayland support for specific apps
    MOZ_ENABLE_WAYLAND = "1";
    ELECTRON_OZONE_PLATFORM_HINT = "wayland";

    #For Anki
    ANKI_WAYLAND = "1";
  };
}

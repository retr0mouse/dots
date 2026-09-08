{
  pkgs,
  user,
  ...
}: {
  imports = [
    ./modules/hyprland
    ./modules/waybar
    ./modules/kitty.nix
    ./modules/zsh.nix
    ./modules/neovim
    ./modules/brave.nix
    ./modules/git.nix
    ./programs.nix
    ./scripts.nix
  ];

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

  home = {
    username = user;
    homeDirectory = "/home/${user}";
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

  programs.ssh = {
    enable = true;

    enableDefaultConfig = false;

    matchBlocks."*" = {
      addKeysToAgent = "yes";
      compression = true;
      serverAliveInterval = 60;
    };
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

  programs.rofi = {
    enable = true;
  };

  programs.hyprlock = {
    enable = true;
    settings = {
      general = {
        hide_cursor = false;
        ignore_empty_input = true;
      };

      animations = {
        enabled = true;
        fade_in = {
          duration = 300;
          bezier = "easeOutQuint";
        };
        fade_out = {
          duration = 300;
          bezier = "easeOutQuint";
        };
      };

      background = [
        {
          path = "screenshot";
          blur_passes = 3;
          blur_size = 8;
        }
      ];

      input-field = [
        {
          size = "200, 50";
          position = "0, -80";
          monitor = "";
          dots_center = true;
          fade_on_empty = false;
          font_color = "rgb(202, 211, 245)";
          inner_color = "rgb(91, 96, 120)";
          outer_color = "rgb(24, 25, 38)";
          outline_thickness = 5;
          shadow_passes = 2;
        }
      ];
      label = [
        {
          monitor = "";
          text = "$LAYOUT"; # current layout
          font_size = 12;
          font_color = "rgb(202, 211, 245)";
          position = "0, -200"; # adjust vertical position
          halign = "center";
          valign = "center";
        }
        {
          monitor = "";
          text = "$TIME"; # 24h format
          font_size = 44;
          font_color = "rgb(202, 211, 245)";
          position = "0, 100"; # adjust position below
          halign = "center";
          valign = "center";
        }
      ];
    };
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

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}

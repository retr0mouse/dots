{pkgs, ...}: let
  vpnControl = pkgs.writeShellApplication {
    name = "vpn-control";
    runtimeInputs = [
      pkgs.bind.dnsutils
      pkgs.libnotify
      pkgs.systemd
    ];
    text = ''
      set -u

      wireguard_unit="wg-quick-wg0.service"
      toggle_unit="wireguard-toggle.service"
      wireguard_dns="10.10.0.1"
      wireguard_home_marker="/run/wireguard-auto.home"

      dns_is_reachable() {
          dig \
              +time=1 \
              +tries=1 \
              +short \
              "@''${wireguard_dns}" \
              example.com \
              A >/dev/null 2>&1
      }

      display_status() {
          if [[ -e "$wireguard_home_marker" ]]; then
              printf '%s\n' '{"text":"󰦝 ","class":"home","tooltip":"WireGuard is disabled on the home network"}'
          elif ! systemctl is-active --quiet "$wireguard_unit"; then
              printf '%s\n' '{"text":"󰦝 ","class":"disconnected","tooltip":"WireGuard is off\nClick to enable"}'
          elif dns_is_reachable; then
              printf '%s\n' '{"text":"󰌾 ","class":"connected","tooltip":"WireGuard is connected\nClick to disable"}'
          else
              printf '%s\n' '{"text":"󰦜 ","class":"error","tooltip":"WireGuard is active but unhealthy\nClick to disable"}'
          fi
      }

      toggle_wireguard() {
          was_active=false
          if systemctl is-active --quiet "$wireguard_unit"; then
              was_active=true
          fi

          if [[ "$was_active" == false && -e "$wireguard_home_marker" ]]; then
              return 0
          fi

          if ! systemctl start "$toggle_unit"; then
              notify-send \
                  --urgency=critical \
                  "WireGuard control failed" \
                  "The guarded toggle service could not be started."
          elif [[ "$was_active" == true ]]; then
              if systemctl is-active --quiet "$wireguard_unit"; then
                  notify-send \
                      --urgency=critical \
                      "WireGuard control failed" \
                      "The tunnel could not be switched off."
              else
                  notify-send "WireGuard disabled" "Automatic activation is paused on this network."
              fi
          elif [[ -e "$wireguard_home_marker" ]]; then
              return 0
          elif systemctl is-active --quiet "$wireguard_unit" && dns_is_reachable; then
              notify-send "WireGuard enabled" "The home DNS server is reachable."
          else
              notify-send \
                  --urgency=critical \
                  "WireGuard unavailable" \
                  "The tunnel failed its DNS check and was switched off."
          fi
      }

      case "''${1:-status}" in
          status)
              display_status
              ;;
          toggle)
              toggle_wireguard
              ;;
          *)
              echo "Usage: vpn-control {status|toggle}" >&2
              exit 2
              ;;
      esac
    '';
  };
in {
  imports = [
    ./home/hyprland
    ./home/quickshell
    ./home/rofi
    ./home/session-controls
    ./home/hyprpolkitagent
    ./home/swaync
    ./home/kitty.nix
    ./home/pwvucontrol
    ./home/brave.nix
    ./packages.nix
    ./scripts.nix
  ];

  config = {
    home.stateVersion = "24.11"; # First-deploy version — do not change.

    programs.zsh.shellAliases.slip = "hyprlock & sleep 0.5 && systemctl suspend";

    home.packages = [
      pkgs.brightnessctl
      pkgs.wireguard-tools
      vpnControl
    ];

    dotfiles.quickshell = {
      showBattery = true;
      showBacklight = true;
      showPowerProfile = true;
      showIntegratedGpu = true;
      showDiscreteGpu = true;
      showVpn = true;
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

      Install.WantedBy = ["graphical-session.target"];
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

      Install.WantedBy = ["graphical-session.target"];
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

      Install.WantedBy = ["graphical-session.target"];
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

      Install.WantedBy = ["graphical-session.target"];
    };

    # UWSM launches applications through the user manager, so keep its
    # environment aligned with the interactive Home Manager session.
    systemd.user.sessionVariables = {
      EDITOR = "nvim";
      VISUAL = "nvim";
      XCURSOR_THEME = "Yaru";
      XCURSOR_SIZE = 24;
    };

    wayland.windowManager.hyprland.systemd.enable = false;

    gtk = {
      enable = true;
      iconTheme = {
        name = "Papirus-Dark";
        package = pkgs.papirus-icon-theme;
      };
    };

    home.pointerCursor = {
      gtk.enable = true;
      x11.enable = true;
      package = pkgs.yaru-theme;
      name = "Yaru";
      size = 24;
    };

    # Default apps
    xdg.desktopEntries.nvim = {
      name = "Neovim";
      genericName = "Text Editor";
      comment = "Edit text and source files in Neovim";
      exec = "${pkgs.kitty}/bin/kitty --class nvim -e ${pkgs.neovim}/bin/nvim %F";
      icon = "nvim";
      terminal = false;
      categories = [
        "Development"
        "TextEditor"
      ];
      mimeType = [
        "application/javascript"
        "application/json"
        "application/toml"
        "application/xml"
        "application/x-javascript"
        "application/x-yaml"
        "application/yaml"
        "text/markdown"
        "text/plain"
        "text/x-c"
        "text/x-c++"
        "text/x-c++hdr"
        "text/x-c++src"
        "text/x-chdr"
        "text/x-csrc"
        "text/x-lua"
        "text/x-python"
        "text/x-qml"
        "text/x-rust"
        "text/x-shellscript"
      ];
    };

    xdg.desktopEntries."yazi-kitty" = {
      name = "Yazi";
      genericName = "File Manager";
      comment = "Browse directories in Yazi";
      exec = "${pkgs.kitty}/bin/kitty --class yazi -e ${pkgs.yazi}/bin/yazi %f";
      icon = "kitty";
      terminal = false;
      noDisplay = true;
      categories = ["System" "FileTools" "FileManager"];
      mimeType = ["inode/directory"];
    };

    xdg.mimeApps = {
      enable = true;

      associations.removed = {
        "application/zip" = "org.prismlauncher.PrismLauncher.desktop";
      };

      defaultApplications = {
        "application/javascript" = "nvim.desktop";
        "application/json" = "nvim.desktop";
        "application/toml" = "nvim.desktop";
        "application/xml" = "nvim.desktop";
        "application/x-javascript" = "nvim.desktop";
        "application/x-yaml" = "nvim.desktop";
        "application/yaml" = "nvim.desktop";
        "image/avif" = "imv.desktop";
        "image/bmp" = "imv.desktop";
        "image/gif" = "imv.desktop";
        "image/heif" = "imv.desktop";
        "image/jpeg" = "imv.desktop";
        "image/jpg" = "imv.desktop";
        "image/jxl" = "imv.desktop";
        "image/pjpeg" = "imv.desktop";
        "image/png" = "imv.desktop";
        "image/qoi" = "imv.desktop";
        "image/svg+xml" = "imv.desktop";
        "image/tiff" = "imv.desktop";
        "image/tiff-fx" = "imv.desktop";
        "image/webp" = "imv.desktop";
        "image/x-bmp" = "imv.desktop";
        "image/x-farbfeld" = "imv.desktop";
        "image/x-png" = "imv.desktop";
        "inode/directory" = "yazi-kitty.desktop";
        "text/html" = "brave-browser.desktop";
        "text/markdown" = "nvim.desktop";
        "text/plain" = "nvim.desktop";
        "text/x-c" = "nvim.desktop";
        "text/x-c++" = "nvim.desktop";
        "text/x-c++hdr" = "nvim.desktop";
        "text/x-c++src" = "nvim.desktop";
        "text/x-chdr" = "nvim.desktop";
        "text/x-csrc" = "nvim.desktop";
        "text/x-lua" = "nvim.desktop";
        "text/x-python" = "nvim.desktop";
        "text/x-qml" = "nvim.desktop";
        "text/x-rust" = "nvim.desktop";
        "text/x-shellscript" = "nvim.desktop";
        "x-scheme-handler/about" = "brave-browser.desktop";
        "x-scheme-handler/http" = "brave-browser.desktop";
        "x-scheme-handler/https" = "brave-browser.desktop";
        "x-scheme-handler/obsidian" = "obsidian.desktop";
        "x-scheme-handler/unknown" = "brave-browser.desktop";
      };

      defaultApplicationPackages = [
        pkgs.file-roller
        pkgs.evince
        pkgs.foliate
        pkgs.libreoffice-qt
        pkgs.vlc
        pkgs.qdigidoc
        pkgs.qbittorrent
      ];
    };

    home.sessionVariables = {
      NIXOS_OZONE_WL = "1"; # Force Wayland for electron apps

      # Wayland support for specific apps
      MOZ_ENABLE_WAYLAND = "1";
      ELECTRON_OZONE_PLATFORM_HINT = "wayland";

      # For Anki
      ANKI_WAYLAND = "1";
    };
  };
}

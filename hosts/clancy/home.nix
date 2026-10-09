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

    # UWSM launches applications through the user manager, so mirror the
    # XCursor variables into systemd's session environment as well.
    systemd.user.sessionVariables = {
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

      # Wayland support for specific apps
      MOZ_ENABLE_WAYLAND = "1";
      ELECTRON_OZONE_PLATFORM_HINT = "wayland";

      # For Anki
      ANKI_WAYLAND = "1";
    };
  };
}

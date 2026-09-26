{
  config,
  lib,
  osConfig,
  pkgs,
  ...
}: let
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
          if ! systemctl is-active --quiet "$wireguard_unit"; then
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
    ../../modules/hyprland
    ../../modules/waybar
    ../../modules/rofi
    ../../modules/session-controls
    ../../modules/hyprpolkitagent
    ../../modules/swaync
    ../../modules/kitty.nix
    ../../modules/pwvucontrol
    ../../modules/brave.nix
    ../../programs.nix
    ../../scripts.nix
  ];

  options.dotfiles.roles.clancy.discordPackage = lib.mkOption {
    type = lib.types.package;
    default = pkgs.discord;
    description = "Discord package used by the Clancy role.";
  };

  config = {
    home.stateVersion = "24.11"; # First-deploy version — do not change.

    programs.zsh.shellAliases.slip = "hyprlock & sleep 0.5 && systemctl suspend";

    home.packages =
      [
        config.dotfiles.roles.clancy.discordPackage
        pkgs.wireguard-tools
        vpnControl
      ]
      ++ lib.optionals osConfig.dotfiles.hardware.backlight [pkgs.brightnessctl];

    # User-facing hardware features follow the assigned physical machine.
    dotfiles.waybar = {
      showBattery = osConfig.dotfiles.hardware.battery;
      showBacklight = osConfig.dotfiles.hardware.backlight;
      showPowerProfile = osConfig.dotfiles.hardware.powerProfiles;
      showIntegratedGpu = osConfig.dotfiles.hardware.integratedGpu;
      showDiscreteGpu = osConfig.dotfiles.hardware.discreteGpu;
      showVpn = osConfig.dotfiles.deployment.activateIdentity;
    };

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

      Install.WantedBy = ["graphical-session.target"];
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
      package = pkgs.bibata-cursors;
      name = "Bibata-Modern-Classic";
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

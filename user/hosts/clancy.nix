{
  lookingGlassPackage,
  pkgs,
  ...
}: let
  mkScript = name: pkgs.writeShellScriptBin name (builtins.readFile ./clancy/${name}.sh);
  mesaEgl = "__EGL_VENDOR_LIBRARY_FILENAMES=/run/opengl-driver/share/glvnd/egl_vendor.d/50_mesa.json";
  passthroughSafeGtkEnvironment = [
    "GSK_RENDERER=ngl"
    mesaEgl
  ];
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
  imports = [../modules/looking-glass.nix];

  dotfiles.waybar = {
    showBacklight = true;
    showBattery = true;
    showDiscreteGpu = true;
    showIntegratedGpu = true;
    showPowerProfile = true;
    showVpn = true;
  };

  programs.looking-glass-client.package = lookingGlassPackage;

  home.packages = [
    (mkScript "dgpu_usage")
    (mkScript "igpu_usage")
    (mkScript "powerprofile")
    vpnControl
  ];

  # Clancy exposes its AMD iGPU under this stable, host-specific name.
  xdg.configFile."uwsm/env-hyprland".text = ''
    export AQ_DRM_DEVICES="/dev/dri/amd-igpu"
  '';

  xdg.configFile."systemd/user/wayland-wm@hyprland.desktop.service.d/10-amd-egl.conf".text = ''
    [Service]
    Environment="${mesaEgl}"
  '';

  systemd.user.services.hyprpaper.Service.Environment = [mesaEgl];

  # Keep GTK's renderer on Mesa so desktop services do not claim the RTX that
  # is reserved for VM passthrough.
  systemd.user.services.swaync.Service.Environment = passthroughSafeGtkEnvironment;

  systemd.user.services.swayosd.Service.Environment = passthroughSafeGtkEnvironment;
}

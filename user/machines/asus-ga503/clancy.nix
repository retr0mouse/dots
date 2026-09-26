{
  lib,
  lookingGlassPackage,
  pkgs,
  ...
}: let
  mkScript = name: pkgs.writeShellScriptBin name (builtins.readFile ./${name}.sh);
  mesaEglVendor = "/run/opengl-driver/share/glvnd/egl_vendor.d/50_mesa.json";
  mesaEgl = "__EGL_VENDOR_LIBRARY_FILENAMES=${mesaEglVendor}";
  passthroughSafeGtkEnvironment = [
    "GSK_RENDERER=ngl"
    mesaEgl
  ];
  discordAmd = pkgs.symlinkJoin {
    name = "discord-amd";
    paths = [pkgs.discord];
    nativeBuildInputs = [pkgs.makeWrapper];
    postBuild = ''
      wrapProgram "$out/opt/Discord/Discord" \
        --set DRI_PRIME 0 \
        --set __EGL_VENDOR_LIBRARY_FILENAMES ${mesaEglVendor} \
        --set VK_DRIVER_FILES /run/opengl-driver/share/vulkan/icd.d/radeon_icd.x86_64.json
    '';
  };
  toggleTouchpad = pkgs.writeShellApplication {
    name = "toggle-touchpad";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.hyprland
      pkgs.swayosd
    ];
    text = ''
      touchpad="asue1209:00-04f3:319f-touchpad"
      state_file="''${XDG_RUNTIME_DIR:?}/clancy-touchpad-disabled-''${HYPRLAND_INSTANCE_SIGNATURE:?}"

      if [[ -e "$state_file" ]]; then
        enabled=true
        message="Touchpad enabled"
        icon="input-touchpad"
      else
        enabled=false
        message="Touchpad disabled"
        icon="touchpad-disabled-symbolic"
      fi

      hyprctl eval "hl.device({ name = \"$touchpad\", enabled = $enabled })"

      if [[ "$enabled" == true ]]; then
        rm -f "$state_file"
      else
        touch "$state_file"
      fi

      swayosd-client --custom-message "$message" --custom-icon "$icon"
    '';
  };
  keyboardBacklight = pkgs.writeShellApplication {
    name = "keyboard-backlight";
    runtimeInputs = [
      pkgs.brightnessctl
      pkgs.swayosd
    ];
    text = ''
      device="asus::kbd_backlight"

      case "''${1:-}" in
        up)
          brightnessctl --quiet --class leds --device "$device" set +1
          ;;
        down)
          brightnessctl --quiet --class leds --device "$device" set 1-
          ;;
        *)
          echo "Usage: keyboard-backlight {up|down}" >&2
          exit 2
          ;;
      esac

      brightness="$(brightnessctl --class leds --device "$device" get)"
      maximum="$(brightnessctl --class leds --device "$device" max)"

      swayosd-client \
        --custom-icon input-keyboard-symbolic \
        --custom-segmented-progress "$brightness:$maximum" \
        --custom-progress-text "$brightness/$maximum"
    '';
  };
in {
  imports = [../../modules/looking-glass.nix];

  home.packages = [
    (mkScript "dgpu_usage")
    (mkScript "igpu_usage")
    (mkScript "powerprofile")
    keyboardBacklight
    toggleTouchpad
  ];

  wayland.windowManager.hyprland.extraConfig = lib.mkAfter ''
    hl.bind("XF86KbdBrightnessUp", hl.dsp.exec_cmd("keyboard-backlight up"), { locked = true })
    hl.bind("XF86KbdBrightnessDown", hl.dsp.exec_cmd("keyboard-backlight down"), { locked = true })
    hl.bind("XF86TouchpadToggle", hl.dsp.exec_cmd("toggle-touchpad"), { locked = true })
  '';

  dotfiles.roles.clancy.discordPackage = discordAmd;

  programs.looking-glass-client.package = lookingGlassPackage;

  # This machine exposes its AMD iGPU under this stable, host-specific name.
  xdg.configFile."uwsm/env-hyprland".text = ''
    export AQ_DRM_DEVICES="/dev/dri/amd-igpu"
  '';

  xdg.configFile."systemd/user/wayland-wm@hyprland.desktop.service.d/10-amd-egl.conf".text = ''
    [Service]
    Environment="${mesaEgl}"
  '';

  # Keep GTK's renderer on Mesa so desktop services do not claim the RTX that
  # is reserved for VM passthrough.
  systemd.user.services.swaync.Service.Environment = passthroughSafeGtkEnvironment;

  systemd.user.services.swayosd.Service.Environment = passthroughSafeGtkEnvironment;
}

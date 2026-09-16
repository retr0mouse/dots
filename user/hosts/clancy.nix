{
  lookingGlassPackage,
  pkgs,
  ...
}: let
  mkScript = name: pkgs.writeShellScriptBin name (builtins.readFile ./clancy/${name}.sh);
in {
  imports = [../modules/looking-glass.nix];

  dotfiles.waybar = {
    showBacklight = true;
    showBattery = true;
    showDiscreteGpu = true;
    showIntegratedGpu = true;
    showPowerProfile = true;
  };

  programs.looking-glass-client.package = lookingGlassPackage;

  home.packages = [
    (mkScript "dgpu_usage")
    (mkScript "igpu_usage")
    (mkScript "powerprofile")
  ];

  # Clancy exposes its AMD iGPU under this stable, host-specific name.
  xdg.configFile."uwsm/env-hyprland".text = ''
    export AQ_DRM_DEVICES="/dev/dri/amd-igpu"
  '';

  xdg.configFile."systemd/user/wayland-wm@hyprland.desktop.service.d/10-amd-egl.conf".text = ''
    [Service]
    Environment="__EGL_VENDOR_LIBRARY_FILENAMES=/run/opengl-driver/share/glvnd/egl_vendor.d/50_mesa.json"
  '';

  systemd.user.services.hyprpaper.Service.Environment = [
    "__EGL_VENDOR_LIBRARY_FILENAMES=/run/opengl-driver/share/glvnd/egl_vendor.d/50_mesa.json"
  ];

  systemd.user.services.swaync.Service.Environment = [
    "__EGL_VENDOR_LIBRARY_FILENAMES=/run/opengl-driver/share/glvnd/egl_vendor.d/50_mesa.json"
  ];
}

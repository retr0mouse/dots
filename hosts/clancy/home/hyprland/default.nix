{
  xdg.configFile."hypr/hyprpaper.conf".text = ''
    splash = false
  '';

  wayland.windowManager.hyprland = {
    enable = true;
    configType = "lua";

    extraConfig = builtins.readFile ./config.lua;
  };
}

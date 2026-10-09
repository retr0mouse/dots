{
  programs.kitty = {
    enable = true;
    settings = {
      font_family = "Fira Code Nerd Font";
      font_size = 12;
      confirm_os_window_close = 0;
      enable_audio_bell = false;
      window_padding_width = 10;
      cursor_shape = "block";
      cursor_blink_interval = 0;
      tab_bar_style = "hidden";
    };
    extraConfig = ''
      background #0f1115
      foreground #d8dee9

      cursor #a8c080
      cursor_text_color #0f1115

      selection_background #334155
      selection_foreground #ffffff


      # black
      color0 #0f1115
      color8 #4b5563

      # red
      color1 #e06c75
      color9 #ff7b86

      # green (accent)
      color2 #a8c080
      color10 #c0d890

      # yellow
      color3 #e5c07b
      color11 #f0d28a

      # blue (less dominant)
      color4 #7aa2f7
      color12 #89b4fa

      # magenta
      color5 #bb9af7
      color13 #cba6f7

      # cyan
      color6 #7dcfff
      color14 #8be9fd

      # white
      color7 #d8dee9
      color15 #ffffff
    '';
  };
}

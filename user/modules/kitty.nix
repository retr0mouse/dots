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
      tab_bar_edge = "top";
      tab_bar_style = "separator";
      tab_separator = ''" "'';
      tab_title_template = "[ {index} | {title} ]";
      active_tab_font_style = "bold";
      inactive_tab_font_style = "bold";
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


      tab_bar_background #0f1115

      active_tab_background #a8c080
      active_tab_foreground #0f1115

      inactive_tab_background #1a1d23
      inactive_tab_foreground #7f8794
    '';
    keybindings = {
      # Switch to tab by index (1-based!)
      "ctrl+1" = "goto_tab 1";
      "ctrl+2" = "goto_tab 2";
      "ctrl+3" = "goto_tab 3";
      "ctrl+4" = "goto_tab 4";
      "ctrl+5" = "goto_tab 5";
      "ctrl+6" = "goto_tab 6";
      "ctrl+7" = "goto_tab 7";
      "ctrl+8" = "goto_tab 8";
      "ctrl+9" = "goto_tab 9";
    };
  };
}

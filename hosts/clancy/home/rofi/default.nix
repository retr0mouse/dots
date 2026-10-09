{pkgs, ...}: {
  programs.rofi = {
    enable = true;
    font = "Iosevka Nerd Font 15";
    terminal = "${pkgs.kitty}/bin/kitty";
    theme = ./theme.rasi;

    extraConfig = {
      modes = "drun,run,window";
      show-icons = false;
      drun-display-format = "{name}";

      display-drun = "apps";
      display-run = "run";
      display-window = "windows";

      matching = "fuzzy";
      sort = true;
      sorting-method = "fzf";
      case-smart = true;
      normalize-match = true;

      cycle = true;
      fixed-num-lines = false;
      click-to-exit = true;
    };
  };
}

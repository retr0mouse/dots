{pkgs, ...}: let
  sessionMenu = pkgs.writeShellApplication {
    name = "session-menu";
    runtimeInputs = [
      pkgs.hyprland
      pkgs.jq
      pkgs.wlogout
    ];
    text = ''
      monitor="$(${pkgs.hyprland}/bin/hyprctl monitors -j \
        | ${pkgs.jq}/bin/jq -c 'map(select(.focused == true))[0] // .[0]')"

      if [[ -z "$monitor" || "$monitor" == "null" ]]; then
        exec ${pkgs.wlogout}/bin/wlogout \
          --buttons-per-row 3 \
          --column-spacing 1 \
          --row-spacing 1 \
          --no-span
      fi

      read -r monitor_id monitor_width monitor_height < <(
        ${pkgs.jq}/bin/jq -r \
          '[.id, (.width / .scale | floor), (.height / .scale | floor)] | @tsv' \
          <<<"$monitor"
      )

      menu_width=$((monitor_width * 44 / 100))
      menu_height=$((monitor_height * 34 / 100))

      ((menu_width > 840)) && menu_width=840
      ((menu_width < 600)) && menu_width=600
      ((menu_height > 380)) && menu_height=380
      ((menu_height < 300)) && menu_height=300

      horizontal_margin=$(((monitor_width - menu_width) / 2))
      vertical_margin=$(((monitor_height - menu_height) / 2))

      ((horizontal_margin < 0)) && horizontal_margin=0
      ((vertical_margin < 0)) && vertical_margin=0

      exec ${pkgs.wlogout}/bin/wlogout \
        --buttons-per-row 3 \
        --column-spacing 1 \
        --row-spacing 1 \
        --margin-left "$horizontal_margin" \
        --margin-right "$horizontal_margin" \
        --margin-top "$vertical_margin" \
        --margin-bottom "$vertical_margin" \
        --primary-monitor "$monitor_id" \
        --no-span
    '';
  };
in {
  home.packages = [sessionMenu];

  services.swayosd = {
    enable = true;
    topMargin = 0.82;
    stylePath = ./swayosd.css;
  };

  programs.hyprlock = {
    enable = true;

    settings = {
      general = {
        hide_cursor = true;
        ignore_empty_input = true;
      };

      animations = {
        enabled = true;
        fade_in = {
          duration = 180;
          bezier = "easeOutQuint";
        };
        fade_out = {
          duration = 180;
          bezier = "easeOutQuint";
        };
      };

      background = [
        {
          monitor = "";
          path = "screenshot";
          color = "rgb(16, 18, 17)";
          blur_passes = 2;
          blur_size = 4;
          brightness = 0.28;
          contrast = 1.05;
          vibrancy = 0.08;
          vibrancy_darkness = 0.0;
        }
      ];

      input-field = [
        {
          monitor = "";
          size = "360, 46";
          position = "0, -55";
          halign = "center";
          valign = "center";

          font_family = "Iosevka Nerd Font";
          font_color = "rgb(197, 200, 197)";
          inner_color = "rgba(16, 18, 17, 0.94)";
          outer_color = "rgb(48, 54, 48)";
          check_color = "rgb(152, 168, 124)";
          fail_color = "rgb(208, 135, 112)";
          capslock_color = "rgb(127, 159, 159)";

          outline_thickness = 1;
          rounding = 0;
          shadow_passes = 0;
          fade_on_empty = false;

          placeholder_text = ''<span foreground="##303630">[ password ]</span>'';
          check_text = "[ checking ]";
          fail_text = "[ denied ]";

          dots_center = true;
          dots_rounding = 0;
          dots_size = 0.22;
          dots_spacing = 0.35;
        }
      ];

      label = [
        {
          monitor = "";
          text = "[ $TIME ]";
          font_family = "Iosevka Nerd Font";
          font_size = 52;
          font_color = "rgb(197, 200, 197)";
          position = "0, 135";
          halign = "center";
          valign = "center";
        }
        {
          monitor = "";
          text = "cmd[update:60000] date '+%a %d %b'";
          font_family = "Iosevka Nerd Font";
          font_size = 15;
          font_color = "rgb(127, 159, 159)";
          position = "0, 88";
          halign = "center";
          valign = "center";
        }
        {
          monitor = "";
          text = "[ locked ]";
          font_family = "Iosevka Nerd Font";
          font_size = 15;
          font_color = "rgb(152, 168, 124)";
          position = "0, 8";
          halign = "center";
          valign = "center";
        }
        {
          monitor = "";
          text = "[ $LAYOUT ]";
          font_family = "Iosevka Nerd Font";
          font_size = 13;
          font_color = "rgb(127, 159, 159)";
          position = "0, -125";
          halign = "center";
          valign = "center";
        }
      ];
    };
  };

  programs.wlogout = {
    enable = true;
    layout = [
      {
        label = "lock";
        action = "hyprlock";
        text = "[l] lock";
        keybind = "l";
        height = 0.5;
        width = 0.5;
        circular = false;
      }
      {
        label = "suspend";
        action = "systemctl suspend";
        text = "[u] suspend";
        keybind = "u";
        height = 0.5;
        width = 0.5;
        circular = false;
      }
      {
        label = "logout";
        action = "loginctl terminate-user $USER";
        text = "[e] logout";
        keybind = "e";
        height = 0.5;
        width = 0.5;
        circular = false;
      }
      {
        label = "hibernate";
        action = "systemctl hibernate";
        text = "[h] hibernate";
        keybind = "h";
        height = 0.5;
        width = 0.5;
        circular = false;
      }
      {
        label = "reboot";
        action = "systemctl reboot";
        text = "[r] reboot";
        keybind = "r";
        height = 0.5;
        width = 0.5;
        circular = false;
      }
      {
        label = "shutdown";
        action = "systemctl poweroff";
        text = "[s] shutdown";
        keybind = "s";
        height = 0.5;
        width = 0.5;
        circular = false;
      }
    ];
    style = ./wlogout.css;
  };
}

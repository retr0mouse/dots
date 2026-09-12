{...}: {
  programs.waybar = {
    enable = true;

    settings = [
      {
        position = "top";

        modules-left = [
          "group/workspaces"
          "group/brightvol"
        ];

        modules-center = [
          "custom/openbracket"
          "clock"
          "custom/closebracket"
        ];

        modules-right = [
          "group/performance"
          "group/system"
        ];

        "custom/openbracket" = {
          format = "[";
          tooltip = false;
        };

        "custom/closebracket" = {
          format = "]";
          tooltip = false;
        };

        "custom/split" = {
          format = "|";
          tooltip = false;
        };

        "custom/powerprofile" = {
          exec = "powerprofile display";
          on-click = "powerprofile toggle";
          interval = 5;
          tooltip = false;
          exec-tooltip = "powerprofile tooltip";
        };

        "group/workspaces" = {
          orientation = "horizontal";
          modules = [
            "custom/openbracket"
            "hyprland/workspaces"
            "custom/closebracket"
          ];
        };

        "hyprland/workspaces" = {
          all-outputs = true;
          warp-on-scroll = false;
          enable-bar-scroll = true;
          disable-scroll-wraparound = true;
          active-only = false;
          format = "{icon}";
        };

        "group/performance" = {
          orientation = "horizontal";
          modules = [
            "custom/openbracket"
            "cpu"
            "custom/split"
            "memory"
            "custom/split"
            "custom/igpu"
            "custom/split"
            "custom/dgpu"
            "custom/closebracket"
          ];
        };

        cpu = {
          format = "CPU:{usage}%";
          tooltip = false;
          interval = 2;
          on-click = "kitty -e btop";
        };

        memory = {
          format = "RAM:{}%";
          tooltip = false;
          interval = 2;
          on-click = "kitty -e btop";
        };

        "custom/igpu" = {
          exec = "igpu_usage";
          interval = 2;
          tooltip = false;
          format = "iGPU:{}";
          on-click = "kitty -e btop";
        };

        "custom/dgpu" = {
          exec = "dgpu_usage";
          interval = 2;
          tooltip = false;
          format = "dGPU:{}";
          on-click = "kitty -e btop";
        };

        "group/brightvol" = {
          orientation = "horizontal";
          tooltip = false;
          modules = [
            "custom/openbracket"
            "backlight"
            "custom/split"
            "pulseaudio"
            "custom/closebracket"
          ];
        };

        pulseaudio = {
          scroll-step = 5;
          format = "{icon} {volume}%";
          format-muted = "MUTED";
          format-icons = {
            default = ["" "" ""];
          };
          on-click = "pwvucontrol";
        };

        backlight = {
          format = "{icon} {percent}%";
          format-icons = ["󰍹 "];
          on-click = "kitty -e hyprmoncfg";
        };

        "group/system" = {
          orientation = "horizontal";
          modules = [
            "custom/openbracket"
            "custom/powerprofile"
            "custom/split"
            "custom/bluetooth"
            "custom/split"
            "network"
            "custom/split"
            "battery"
            "custom/split"
            "custom/swaync"
            "custom/closebracket"
          ];
        };

        clock = {
          format = "{:%H:%M}";
          tooltip-format = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
        };

        battery = {
          states = {
            warning = 30;
            critical = 15;
          };
          events = {
            on-discharging-warning = "notify-send -u normal 'Low Battery'";
            on-discharging-critical = "notify-send -u critical 'Very Low Battery'";
          };
          format = "{icon} {capacity}%";
          format-charging = "󰂄 {capacity}%";
          format-icons = ["󰁺" "󰁻" "󰁼" "󰁽" "󰁾" "󰁿" "󰂀" "󰂁" "󰁹"];
          on-click = "wlogout";
        };

        "custom/swaync" = {
          format = " ";
          tooltip = false;
          on-click = "swaync-client --toggle-panel";
        };

        network = {
          format-wifi = "{icon} ";
          format-ethernet = "󰈀 LAN";
          format-disconnected = "󰖪 ";
          tooltip-format = "{ipaddr}\n{essid} ({signalStrength}%)";
          on-click = "kitty -e wlctl";
          format-icons = ["󰤯" "󰤟" "󰤢" "󰤥" "󰤨"];
        };

        "custom/bluetooth" = {
          exec = "bluetooth_status";
          return-type = "json";
          interval = 2;
          on-click = "kitty -e bluetui";
        };
      }
    ];

    style = builtins.readFile ./style.css;
  };
}

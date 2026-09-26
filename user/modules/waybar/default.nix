{
  config,
  lib,
  ...
}: let
  cfg = config.dotfiles.waybar;
in {
  options.dotfiles.waybar = {
    showBattery = lib.mkEnableOption "the battery widget";
    showDiscreteGpu = lib.mkEnableOption "the discrete GPU widget";
    showIntegratedGpu = lib.mkEnableOption "the integrated GPU widget";
    showPowerProfile = lib.mkEnableOption "the power-profile widget";
    showVpn = lib.mkEnableOption "the WireGuard VPN widget";
  };

  config.programs.waybar = {
    enable = true;

    settings = [
      {
        position = "top";
        height = 28;
        spacing = 0;
        reload_style_on_change = true;

        modules-left = [
          "custom/dashboard"
          "group/workspaces"
        ];

        modules-center = ["group/performance"];

        modules-right = [
          "group/system"
          "group/datetime"
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

        "custom/vpn" = {
          exec = "vpn-control status";
          on-click = "vpn-control toggle";
          interval = 5;
          return-type = "json";
        };

        "custom/dashboard" = {
          format = " ";
          tooltip = false;
          on-click = "swaync-client --toggle-panel";
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
          all-outputs = false;
          warp-on-scroll = false;
          enable-bar-scroll = true;
          disable-scroll-wraparound = true;
          active-only = false;
          format = "{icon}";
        };

        "group/performance" = {
          orientation = "horizontal";
          modules =
            [
              "custom/openbracket"
              "cpu"
              "custom/split"
              "memory"
            ]
            ++ lib.optionals cfg.showIntegratedGpu [
              "custom/split"
              "custom/igpu"
            ]
            ++ lib.optionals cfg.showDiscreteGpu [
              "custom/split"
              "custom/dgpu"
            ]
            ++ ["custom/closebracket"];
        };

        cpu = {
          format = "CPU:{usage}%";
          tooltip = false;
          interval = 2;
          on-click = "kitty --class waybar-performance --title '[ performance ]' -e btop";
        };

        memory = {
          format = "RAM:{}%";
          tooltip = false;
          interval = 2;
          on-click = "kitty --class waybar-performance --title '[ performance ]' -e btop";
        };

        "custom/igpu" = {
          exec = "igpu_usage";
          interval = 2;
          tooltip = false;
          format = "iGPU:{}";
          on-click = "kitty --class waybar-performance --title '[ performance ]' -e btop";
        };

        "custom/dgpu" = {
          exec = "dgpu_usage";
          interval = 2;
          tooltip = false;
          format = "dGPU:{}";
          on-click = "kitty --class waybar-performance --title '[ performance ]' -e btop";
        };

        "group/datetime" = {
          orientation = "horizontal";
          modules = [
            "custom/openbracket"
            "clock#date"
            "custom/split"
            "clock#time"
            "custom/closebracket"
          ];
        };

        "group/system" = {
          orientation = "horizontal";
          modules =
            ["custom/openbracket"]
            ++ lib.optionals cfg.showPowerProfile [
              "custom/powerprofile"
              "custom/split"
            ]
            ++ [
              "custom/bluetooth"
              "custom/split"
              "network"
            ]
            ++ lib.optionals cfg.showVpn [
              "custom/split"
              "custom/vpn"
            ]
            ++ lib.optionals cfg.showBattery [
              "custom/split"
              "battery"
            ]
            ++ ["custom/closebracket"];
        };

        "clock#date" = {
          format = "{:%d/%m/%Y}";
          tooltip = false;
        };

        "clock#time" = {
          format = "{:%H:%M}";
          tooltip = false;
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
          on-click = "session-menu";
        };

        network = {
          format-wifi = "{icon} ";
          format-ethernet = "󰈀 LAN";
          format-disconnected = "󰖪 ";
          tooltip-format = "{ipaddr}\n{essid} ({signalStrength}%)";
          on-click = "kitty --class waybar-network --title '[ network ]' -e wlctl";
          format-icons = ["󰤯" "󰤟" "󰤢" "󰤥" "󰤨"];
        };

        "custom/bluetooth" = {
          exec = "bluetooth_status";
          return-type = "json";
          interval = 2;
          on-click = "kitty --class waybar-bluetooth --title '[ bluetooth ]' -e bluetui";
        };
      }
    ];

    style = builtins.readFile ./style.css;
  };
}

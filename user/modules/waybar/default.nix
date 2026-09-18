{
  config,
  lib,
  ...
}: let
  cfg = config.dotfiles.waybar;
in {
  options.dotfiles.waybar = {
    showBacklight = lib.mkEnableOption "the display backlight widget";
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

        "custom/vpn" = {
          exec = "vpn-control status";
          on-click = "vpn-control toggle";
          interval = 5;
          return-type = "json";
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
          modules =
            ["custom/openbracket"]
            ++ lib.optionals cfg.showBacklight [
              "backlight"
              "custom/split"
            ]
            ++ [
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
            ++ [
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

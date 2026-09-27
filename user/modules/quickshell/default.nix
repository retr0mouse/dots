{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.dotfiles.quickshell;

  quickshellStatus = pkgs.writeShellApplication {
    name = "quickshell-status";
    runtimeInputs = with pkgs; [
      brightnessctl
      coreutils
      gawk
      gnugrep
      jq
      networkmanager
    ];
    text = ''
      read -r _ user nice system idle iowait irq softirq steal _ < /proc/stat
      cpu_idle=$((idle + iowait))
      cpu_total=$((user + nice + system + idle + iowait + irq + softirq + steal))

      memory_percent="$(${pkgs.gawk}/bin/awk '
        /^MemTotal:/ { total = $2 }
        /^MemAvailable:/ { available = $2 }
        END {
          if (total > 0) printf "%.0f", (total - available) * 100 / total
          else print 0
        }
      ' /proc/meminfo)"

      network_type="disconnected"
      network_name="offline"
      while IFS=: read -r _device type state connection; do
        if [[ "$state" == "connected" && ("$type" == "wifi" || "$type" == "ethernet") ]]; then
          network_type="$type"
          network_name="$connection"
          break
        fi
      done < <(nmcli --terse --escape no --fields DEVICE,TYPE,STATE,CONNECTION device status 2>/dev/null || true)

      battery_capacity=0
      battery_status="Unknown"
      shopt -s nullglob
      batteries=(/sys/class/power_supply/BAT*)
      if (( ''${#batteries[@]} > 0 )); then
        battery_capacity="$(<"''${batteries[0]}/capacity")"
        battery_status="$(<"''${batteries[0]}/status")"
      fi

      brightness=0
      brightness_max=1
      if [[ -n "''${QS_BACKLIGHT_DEVICE:-}" ]] && brightnessctl --device "$QS_BACKLIGHT_DEVICE" get >/dev/null 2>&1; then
        brightness="$(brightnessctl --device "$QS_BACKLIGHT_DEVICE" get)"
        brightness_max="$(brightnessctl --device "$QS_BACKLIGHT_DEVICE" max)"
      fi

      igpu="N/A"
      dgpu="N/A"
      power_profile=""
      bluetooth_text="󰂲"
      bluetooth_tooltip="Bluetooth unavailable"
      vpn_text=""
      vpn_class=""
      vpn_tooltip=""

      command -v igpu_usage >/dev/null 2>&1 && igpu="$(igpu_usage 2>/dev/null || printf N/A)"
      command -v dgpu_usage >/dev/null 2>&1 && dgpu="$(dgpu_usage 2>/dev/null || printf N/A)"
      command -v powerprofile >/dev/null 2>&1 && power_profile="$(powerprofile display 2>/dev/null || true)"

      [[ "$igpu" =~ ^([0-9]+%|N/A)$ ]] || igpu="N/A"
      [[ "$dgpu" =~ ^([0-9]+%|N/A|TAKEN)$ ]] || dgpu="N/A"

      if command -v bluetooth_status >/dev/null 2>&1; then
        bluetooth_json="$(bluetooth_status 2>/dev/null || true)"
        if [[ -n "$bluetooth_json" ]]; then
          bluetooth_text="$(jq -r '.text // "󰂲"' <<<"$bluetooth_json")"
          bluetooth_tooltip="$(jq -r '.tooltip // "Bluetooth"' <<<"$bluetooth_json")"
        fi
      fi

      if command -v vpn-control >/dev/null 2>&1; then
        vpn_json="$(vpn-control status 2>/dev/null || true)"
        if [[ -n "$vpn_json" ]]; then
          vpn_text="$(jq -r '.text // ""' <<<"$vpn_json")"
          vpn_class="$(jq -r '.class // ""' <<<"$vpn_json")"
          vpn_tooltip="$(jq -r '.tooltip // "WireGuard"' <<<"$vpn_json")"
        fi
      fi

      jq -cn \
        --argjson cpuTotal "$cpu_total" \
        --argjson cpuIdle "$cpu_idle" \
        --argjson memory "$memory_percent" \
        --arg igpu "$igpu" \
        --arg dgpu "$dgpu" \
        --arg powerProfile "$power_profile" \
        --arg bluetoothText "$bluetooth_text" \
        --arg bluetoothTooltip "$bluetooth_tooltip" \
        --arg networkType "$network_type" \
        --arg networkName "$network_name" \
        --arg vpnText "$vpn_text" \
        --arg vpnClass "$vpn_class" \
        --arg vpnTooltip "$vpn_tooltip" \
        --argjson batteryCapacity "$battery_capacity" \
        --arg batteryStatus "$battery_status" \
        --argjson brightness "$brightness" \
        --argjson brightnessMax "$brightness_max" \
        '{
          cpuTotal: $cpuTotal,
          cpuIdle: $cpuIdle,
          memory: $memory,
          igpu: $igpu,
          dgpu: $dgpu,
          powerProfile: $powerProfile,
          bluetoothText: $bluetoothText,
          bluetoothTooltip: $bluetoothTooltip,
          networkType: $networkType,
          networkName: $networkName,
          vpnText: $vpnText,
          vpnClass: $vpnClass,
          vpnTooltip: $vpnTooltip,
          batteryCapacity: $batteryCapacity,
          batteryStatus: $batteryStatus,
          brightness: $brightness,
          brightnessMax: $brightnessMax
        }'
    '';
  };

  quickshellFetch = pkgs.writeShellApplication {
    name = "quickshell-fetch";
    runtimeInputs = with pkgs; [
      coreutils
      gnugrep
      jq
      nix
      pciutils
      procps
    ];
    text = ''
      # shellcheck disable=SC1091
      source /etc/os-release

      package_paths="$(nix-store --query --requisites /run/current-system 2>/dev/null || true)"
      if [[ -n "$package_paths" ]]; then
        package_count="$(wc -l <<<"$package_paths")"
      else
        package_count=0
      fi
      cpu="$(${pkgs.gnugrep}/bin/grep -m1 '^model name' /proc/cpuinfo | cut -d: -f2- | sed 's/^[[:space:]]*//' || true)"
      gpu="$(lspci 2>/dev/null | ${pkgs.gnugrep}/bin/grep -Ei 'VGA compatible controller|3D controller' | head -n1 | sed -E 's/^[[:xdigit:]]+:[[:xdigit:]]+\.[[:xdigit:]]+[[:space:]]+//' || true)"

      jq -cn \
        --arg user "''${USER:-unknown}" \
        --arg host "$(hostname)" \
        --arg os "''${PRETTY_NAME:-NixOS}" \
        --arg kernel "$(uname -r)" \
        --arg uptime "$(${pkgs.procps}/bin/uptime -p | sed 's/^up //')" \
        --arg packages "$package_count (system closure)" \
        --arg shell "$(basename "''${SHELL:-zsh}")" \
        --arg compositor "Hyprland" \
        --arg cpu "$cpu" \
        --arg gpu "$gpu" \
        '{
          user: $user,
          host: $host,
          os: $os,
          kernel: $kernel,
          uptime: $uptime,
          packages: $packages,
          shell: $shell,
          compositor: $compositor,
          cpu: $cpu,
          gpu: $gpu
        }'
    '';
  };

  quickshellAudioDevice = pkgs.writeShellApplication {
    name = "quickshell-audio-device";
    runtimeInputs = with pkgs; [
      pulseaudio
      wireplumber
    ];
    text = ''
      kind="''${1:-}"
      node_id="''${2:-}"
      node_name="''${3:-}"

      if [[ -z "$node_id" || -z "$node_name" ]]; then
        echo "usage: quickshell-audio-device output|input NODE_ID NODE_NAME" >&2
        exit 2
      fi

      case "$kind" in
        output)
          wpctl set-default "$node_id"
          if pactl info >/dev/null 2>&1; then
            pactl set-default-sink "$node_name"
            while IFS=$'\t' read -r stream_id _; do
              [[ -n "$stream_id" ]] && pactl move-sink-input "$stream_id" "$node_name" || true
            done < <(pactl list short sink-inputs)
          fi
          ;;
        input)
          wpctl set-default "$node_id"
          if pactl info >/dev/null 2>&1; then
            pactl set-default-source "$node_name"
            while IFS=$'\t' read -r stream_id _; do
              [[ -n "$stream_id" ]] && pactl move-source-output "$stream_id" "$node_name" || true
            done < <(pactl list short source-outputs)
          fi
          ;;
        *)
          echo "unknown audio device kind: $kind" >&2
          exit 2
          ;;
      esac
    '';
  };

  quickshellNetworkDetails = pkgs.writeShellApplication {
    name = "quickshell-network-details";
    runtimeInputs = with pkgs; [
      coreutils
      gawk
      jq
      networkmanager
    ];
    text = ''
      device=""
      type="disconnected"
      while IFS=: read -r candidate candidate_type state _; do
        if [[ "$state" == "connected" && ("$candidate_type" == "wifi" || "$candidate_type" == "ethernet") ]]; then
          device="$candidate"
          type="$candidate_type"
          break
        fi
      done < <(nmcli --terse --escape no --fields DEVICE,TYPE,STATE,CONNECTION device status 2>/dev/null || true)

      connection=""
      ip_address=""
      gateway=""
      dns=""
      mac=""
      mtu=""
      speed=""
      frequency=""
      rx_bytes=0
      tx_bytes=0

      if [[ -n "$device" ]]; then
        connection="$(nmcli --escape no --get-values GENERAL.CONNECTION device show "$device" 2>/dev/null | head -n1 || true)"
        ip_address="$(nmcli --escape no --get-values IP4.ADDRESS device show "$device" 2>/dev/null | head -n1 || true)"
        gateway="$(nmcli --escape no --get-values IP4.GATEWAY device show "$device" 2>/dev/null | head -n1 || true)"
        dns="$(nmcli --escape no --get-values IP4.DNS device show "$device" 2>/dev/null | ${pkgs.gawk}/bin/awk 'NF { gsub(/ \| /, ", "); if (out != "") out = out ", "; out = out $0 } END { print out }')"
        mac="$(nmcli --escape no --get-values GENERAL.HWADDR device show "$device" 2>/dev/null | head -n1 || true)"

        [[ -r "/sys/class/net/$device/mtu" ]] && mtu="$(<"/sys/class/net/$device/mtu")"
        [[ -r "/sys/class/net/$device/statistics/rx_bytes" ]] && rx_bytes="$(<"/sys/class/net/$device/statistics/rx_bytes")"
        [[ -r "/sys/class/net/$device/statistics/tx_bytes" ]] && tx_bytes="$(<"/sys/class/net/$device/statistics/tx_bytes")"

        if [[ "$type" == "wifi" ]]; then
          wifi_line="$(nmcli --terse --escape no --fields IN-USE,SIGNAL,FREQ,RATE device wifi list ifname "$device" 2>/dev/null | ${pkgs.gawk}/bin/awk -F: '$1 == "*" { print; exit }')"
          IFS=: read -r _ _ frequency speed <<<"$wifi_line"
        elif [[ -r "/sys/class/net/$device/speed" ]]; then
          speed="$(<"/sys/class/net/$device/speed") Mbit/s"
        fi
      fi

      jq -cn \
        --arg device "$device" \
        --arg type "$type" \
        --arg connection "$connection" \
        --arg ip "$ip_address" \
        --arg gateway "$gateway" \
        --arg dns "$dns" \
        --arg mac "$mac" \
        --arg mtu "$mtu" \
        --arg speed "$speed" \
        --arg frequency "$frequency" \
        --argjson rxBytes "$rx_bytes" \
        --argjson txBytes "$tx_bytes" \
        '{
          device: $device,
          type: $type,
          connection: $connection,
          ip: $ip,
          gateway: $gateway,
          dns: $dns,
          mac: $mac,
          mtu: $mtu,
          speed: $speed,
          frequency: $frequency,
          rxBytes: $rxBytes,
          txBytes: $txBytes
        }'
    '';
  };

  boolString = value:
    if value
    then "1"
    else "0";
in {
  options = {
    dotfiles.desktopBar = lib.mkOption {
      type = lib.types.enum ["quickshell" "waybar"];
      default = "waybar";
      description = "Desktop bar implementation to start with the graphical session.";
    };

    dotfiles.quickshell = {
      showBattery = lib.mkEnableOption "the battery widget";
      showBacklight = lib.mkEnableOption "the display brightness widget";
      showDiscreteGpu = lib.mkEnableOption "the discrete GPU widget";
      showIntegratedGpu = lib.mkEnableOption "the integrated GPU widget";
      showPowerProfile = lib.mkEnableOption "the power-profile widget";
      showVpn = lib.mkEnableOption "the WireGuard VPN widget";
      backlightDevice = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = "Backlight device controlled by the QuickShell brightness slider.";
      };
    };
  };

  config = {
    home.packages = [
      pkgs.quickshell
      quickshellAudioDevice
      quickshellFetch
      quickshellNetworkDetails
      quickshellStatus
    ];

    xdg.configFile = {
      "quickshell/dots/shell.qml".source = ./shell.qml;
      "quickshell/dots/Bar.qml".source = ./Bar.qml;
      "quickshell/dots/BarButton.qml".source = ./BarButton.qml;
      "quickshell/dots/AudioPanel.qml".source = ./AudioPanel.qml;
      "quickshell/dots/AudioVolumeRow.qml".source = ./AudioVolumeRow.qml;
      "quickshell/dots/BluetoothPanel.qml".source = ./BluetoothPanel.qml;
      "quickshell/dots/CalendarPanel.qml".source = ./CalendarPanel.qml;
      "quickshell/dots/ControlPopup.qml".source = ./ControlPopup.qml;
      "quickshell/dots/FetchPanel.qml".source = ./FetchPanel.qml;
      "quickshell/dots/NetworkPanel.qml".source = ./NetworkPanel.qml;
      "quickshell/dots/PowerPanel.qml".source = ./PowerPanel.qml;
      "quickshell/dots/SystemData.qml".source = ./SystemData.qml;
    };

    systemd.user.services.quickshell = lib.mkIf (config.dotfiles.desktopBar == "quickshell") {
      Unit = {
        Description = "QuickShell desktop bar";
        After = ["graphical-session.target"];
        PartOf = ["graphical-session.target"];
        Conflicts = ["waybar.service"];
      };

      Service = {
        ExecStart = "${pkgs.quickshell}/bin/qs -c dots";
        Restart = "on-failure";
        RestartSec = 1;
        Environment = [
          "QS_NO_RELOAD_POPUP=1"
          "QS_AUDIO_DEVICE_COMMAND=${quickshellAudioDevice}/bin/quickshell-audio-device"
          "QS_STATUS_COMMAND=${quickshellStatus}/bin/quickshell-status"
          "QS_FETCH_COMMAND=${quickshellFetch}/bin/quickshell-fetch"
          "QS_NETWORK_DETAILS_COMMAND=${quickshellNetworkDetails}/bin/quickshell-network-details"
          "QS_SHOW_BATTERY=${boolString cfg.showBattery}"
          "QS_SHOW_BACKLIGHT=${boolString cfg.showBacklight}"
          "QS_SHOW_DGPU=${boolString cfg.showDiscreteGpu}"
          "QS_SHOW_IGPU=${boolString cfg.showIntegratedGpu}"
          "QS_SHOW_POWER_PROFILE=${boolString cfg.showPowerProfile}"
          "QS_SHOW_VPN=${boolString cfg.showVpn}"
          "QS_BACKLIGHT_DEVICE=${cfg.backlightDevice}"
        ];
      };

      Install.WantedBy = ["graphical-session.target"];
    };
  };
}

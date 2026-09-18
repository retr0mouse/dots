{
  config,
  lib,
  pkgs,
  inputs,
  username,
  ...
}: let
  wireguardHomeNetworkFile = "/etc/secrets/wireguard-home-network.env";
  wireguardUnit = "wg-quick-wg0.service";
  wireguardDns = "10.10.0.1";
  wireguardPolicyMarker = "/run/wireguard-auto.blocked";
  wireguardPolicyLock = "/run/wireguard-auto.lock";

  checkWireguardDns = pkgs.writeShellScript "check-wireguard-dns" ''
    for _attempt in 1 2 3 4 5; do
      if ${pkgs.bind.dnsutils}/bin/dig \
        +time=1 \
        +tries=1 \
        +short \
        @${wireguardDns} \
        example.com \
        A >/dev/null 2>&1; then
        exit 0
      fi

      ${pkgs.coreutils}/bin/sleep 1
    done

    exit 1
  '';

  getPrimaryConnectionUuid = pkgs.writeShellScript "get-primary-connection-uuid" ''
    ${pkgs.networkmanager}/bin/nmcli \
      -t \
      -f UUID,TYPE,DEVICE \
      connection show --active \
      | ${pkgs.gawk}/bin/awk -F: \
        '$2 == "802-11-wireless" || $2 == "802-3-ethernet" { print $1; exit }'
  '';

  wireguardAuto = pkgs.writeShellScript "wireguard-auto" ''
    set -u

    exec 9>"${wireguardPolicyLock}"
    ${pkgs.util-linux}/bin/flock 9

    wifi_uuid="$(${pkgs.networkmanager}/bin/nmcli \
      -g GENERAL.CON-UUID \
      device show wlp4s0 2>/dev/null || true)"
    connection_uuid="$(${getPrimaryConnectionUuid})"
    connectivity="$(${pkgs.networkmanager}/bin/nmcli \
      -t \
      -f CONNECTIVITY \
      general 2>/dev/null || true)"
    default_gateway="$(${pkgs.iproute2}/bin/ip -4 route show default \
      | ${pkgs.gawk}/bin/awk 'NR == 1 { print $3 }')"
    default_interface="$(${pkgs.iproute2}/bin/ip -4 route show default \
      | ${pkgs.gawk}/bin/awk 'NR == 1 { print $5 }')"
    gateway_mac=""

    if [[ -n "$default_gateway" && -n "$default_interface" ]]; then
      gateway_mac="$(${pkgs.iproute2}/bin/ip neigh show \
        "$default_gateway" \
        dev "$default_interface" \
        | ${pkgs.gawk}/bin/awk '/lladdr/ { print tolower($5); exit }')"
    fi

    is_home_network=false

    for trusted_uuid in ''${WIREGUARD_HOME_WIFI_UUIDS:-}; do
      if [[ "$wifi_uuid" == "$trusted_uuid" ]]; then
        is_home_network=true
        break
      fi
    done

    if [[ -n "''${WIREGUARD_HOME_GATEWAY_MAC:-}" ]] \
      && [[ "$gateway_mac" == "$WIREGUARD_HOME_GATEWAY_MAC" ]]; then
      is_home_network=true
    fi

    if [[ "$is_home_network" == true ]]; then
      ${pkgs.systemd}/bin/systemctl stop ${wireguardUnit}
      ${pkgs.coreutils}/bin/rm -f "${wireguardPolicyMarker}"
      echo "WireGuard disabled on the home network"
      exit 0
    fi

    if [[ -z "$connection_uuid" ]]; then
      ${pkgs.systemd}/bin/systemctl stop ${wireguardUnit}
      ${pkgs.coreutils}/bin/rm -f "${wireguardPolicyMarker}"
      echo "WireGuard disabled because there is no active network"
      exit 0
    fi

    if ${pkgs.systemd}/bin/systemctl is-active --quiet ${wireguardUnit}; then
      if ${checkWireguardDns}; then
        ${pkgs.coreutils}/bin/rm -f "${wireguardPolicyMarker}"
        exit 0
      fi

      ${pkgs.systemd}/bin/systemctl stop ${wireguardUnit}
      printf '%s\n' "$connection_uuid" >"${wireguardPolicyMarker}"
      echo "WireGuard stopped because its DNS server is unreachable" >&2
      exit 0
    fi

    if [[ "$connectivity" != "full" ]]; then
      echo "WireGuard left off until NetworkManager reports full connectivity"
      exit 0
    fi

    if [[ -r "${wireguardPolicyMarker}" ]] \
      && [[ "$(${pkgs.coreutils}/bin/head -n 1 "${wireguardPolicyMarker}")" == "$connection_uuid" ]]; then
      echo "WireGuard automatic retry suppressed on this network"
      exit 0
    fi

    if ${pkgs.systemd}/bin/systemctl start ${wireguardUnit} \
      && ${checkWireguardDns}; then
      ${pkgs.coreutils}/bin/rm -f "${wireguardPolicyMarker}"
      echo "WireGuard enabled and its DNS server is reachable"
      exit 0
    fi

    ${pkgs.systemd}/bin/systemctl stop ${wireguardUnit}
    printf '%s\n' "$connection_uuid" >"${wireguardPolicyMarker}"
    echo "WireGuard failed its DNS check and was rolled back" >&2
  '';

  wireguardToggle = pkgs.writeShellScript "wireguard-toggle" ''
    set -u

    exec 9>"${wireguardPolicyLock}"
    ${pkgs.util-linux}/bin/flock 9

    connection_uuid="$(${getPrimaryConnectionUuid})"

    if ${pkgs.systemd}/bin/systemctl is-active --quiet ${wireguardUnit}; then
      ${pkgs.systemd}/bin/systemctl stop ${wireguardUnit}

      if [[ -n "$connection_uuid" ]]; then
        printf '%s\n' "$connection_uuid" >"${wireguardPolicyMarker}"
      fi

      echo "WireGuard disabled manually"
      exit 0
    fi

    ${pkgs.coreutils}/bin/rm -f "${wireguardPolicyMarker}"

    if ${pkgs.systemd}/bin/systemctl start ${wireguardUnit} \
      && ${checkWireguardDns}; then
      echo "WireGuard enabled manually"
      exit 0
    fi

    ${pkgs.systemd}/bin/systemctl stop ${wireguardUnit}

    if [[ -n "$connection_uuid" ]]; then
      printf '%s\n' "$connection_uuid" >"${wireguardPolicyMarker}"
    fi

    echo "WireGuard failed its DNS check and was rolled back" >&2
    exit 0
  '';

  wireguardDispatcher = pkgs.writeShellScript "wireguard-dispatcher" ''
    case "''${2:-}" in
      up|down|connectivity-change)
        ${pkgs.systemd}/bin/systemctl --no-block restart wireguard-auto.service
        ;;
    esac
  '';
in {
  imports = [
    ../../modules/desktop.nix
    ./hardware-configuration.nix
    ./vfio.nix
    ./looking-glass.nix
    inputs.nixos-hardware.nixosModules.asus-zephyrus-ga503
  ];

  home-manager.users.${username}.imports = [../../../user/hosts/clancy.nix];

  networking.hostName = "clancy";
  networking.wg-quick.interfaces = {
    wg0 = {
      autostart = false;
      address = ["10.10.0.6/32"];
      dns = ["10.10.0.1"];
      privateKeyFile = "/etc/wireguard/privatekey";

      peers = [
        {
          publicKey = "H/aACRc0usVuOYhIQrD4hYQKU7xePHWEwkX91Wm/yFI=";
          allowedIPs = ["10.10.0.0/24" "192.168.0.0/24"];
          endpoint = "voldsoy.duckdns.org:51820";
          persistentKeepalive = 25;
        }
      ];
    };
  };

  networking.networkmanager.dispatcherScripts = [
    {
      source = wireguardDispatcher;
      type = "basic";
    }
  ];

  systemd.services.wireguard-auto = {
    description = "Apply the automatic WireGuard home/away policy";
    wants = ["NetworkManager.service"];
    after = ["NetworkManager.service"];
    wantedBy = ["multi-user.target"];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = wireguardAuto;
      EnvironmentFile = wireguardHomeNetworkFile;
    };
  };

  systemd.services.wireguard-toggle = {
    description = "Toggle WireGuard with DNS health checking";
    wants = ["NetworkManager.service"];
    after = ["NetworkManager.service"];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = wireguardToggle;
    };
  };

  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
      if (
        action.id == "org.freedesktop.systemd1.manage-units" &&
        action.lookup("unit") == "wireguard-toggle.service" &&
        action.lookup("verb") == "start" &&
        subject.user == "${username}" &&
        subject.local &&
        subject.active
      ) {
        return polkit.Result.YES;
      }
    });
  '';

  services.asusd.enable = true;
  services.power-profiles-daemon.enable = true;
  services.logind.settings.Login.HandleLidSwitchExternalPower = "ignore";

  services.libinput = {
    enable = true;
    touchpad.naturalScrolling = true;
  };

  services.xserver.enable = true;

  services.udev.extraRules = ''
    KERNEL=="card*", \
    KERNELS=="0000:06:00.0", \
    SUBSYSTEM=="drm", \
    SUBSYSTEMS=="pci", \
    SYMLINK+="dri/amd-igpu"
  '';

  services.xserver.videoDrivers = ["amdgpu" "nvidia"];

  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = true;
    powerManagement.finegrained = true;

    open = true;
    nvidiaSettings = true;

    package = config.boot.kernelPackages.nvidiaPackages.stable;

    prime = {
      amdgpuBusId = lib.mkForce "PCI:6:0:0";
      nvidiaBusId = "PCI:1:0:0";

      offload = {
        enable = true;
        enableOffloadCmd = true;
      };
    };
  };

  hardware.graphics.extraPackages = with pkgs; [
    mesa
  ];

  system.stateVersion = "25.11";
}

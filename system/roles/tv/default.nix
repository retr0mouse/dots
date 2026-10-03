{
  lib,
  pkgs,
  username,
  ...
}: let
  # Jellyfin handles incompatible media on the server, so Kodi can share the
  # regular Plasma Wayland session instead of taking over DRM and a VT.
  kodiTv = pkgs.kodi-wayland.withPackages (kodiPackages: [
    kodiPackages.jellyfin
    kodiPackages.typing_extensions
  ]);

  jellyfinTv = pkgs.symlinkJoin {
    name = "jellyfin-tv";
    paths = [
      (pkgs.writeShellScriptBin "jellyfin-tv" ''
        exec ${lib.getExe' pkgs.jellyfin-desktop "jellyfin-desktop"} --tv --fullscreen "$@"
      '')
      (pkgs.makeDesktopItem {
        name = "jellyfin-tv";
        desktopName = "Jellyfin";
        exec = "jellyfin-tv %u";
        icon = "${pkgs.jellyfin-desktop}/share/icons/hicolor/scalable/apps/org.jellyfin.JellyfinDesktop.svg";
        categories = [
          "AudioVideo"
          "Video"
        ];
      })
    ];
  };
in {
  networking.networkmanager.enable = true;

  hardware = {
    bluetooth = {
      enable = true;
      powerOnBoot = true;
    };
    graphics.enable = true;
  };

  fonts.packages = [pkgs.nerd-fonts.fira-code];

  services.desktopManager.plasma6.enable = true;

  services.displayManager = {
    defaultSession = "plasma-bigscreen-wayland";
    sessionPackages = [pkgs.kdePackages.plasma-bigscreen];

    autoLogin = {
      enable = true;
      user = username;
    };

    sddm = {
      enable = true;
      wayland.enable = true;
      autoLogin.relogin = true;
    };
  };

  security.rtkit.enable = true;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
  };

  # A TV appliance should not suspend itself behind the display. The TV can
  # still be powered off independently, including through HDMI-CEC.
  services.logind.settings.Login = {
    HandlePowerKey = "poweroff";
    IdleAction = "ignore";
  };

  systemd.targets = {
    sleep.enable = false;
    suspend.enable = false;
    hibernate.enable = false;
    hybrid-sleep.enable = false;
  };

  programs = {
    kde-pim.enable = false;

    # Bigscreen's home header imports the KDE Connect QML module directly.
    kdeconnect.enable = true;
  };

  environment.systemPackages = with pkgs; [
    firefox
    jellyfinTv
    kdePackages.plasma-bigscreen
    kdePackages.plasmatube
    kodiTv
    libcec
    v4l-utils
  ];

  users.users.${username} = {
    extraGroups = [
      "audio"
      "input"
      "networkmanager"
      "video"
    ];

    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBc99rk0UvmyyD1cl6dFs81ExTE8xGeRIOlIQkWUd9iL ga503qm"
    ];
  };

  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = false;
  };

  # The account has no reusable password on this appliance. Administrative
  # access is restricted to the SSH key above or a local root console.
  security.sudo.wheelNeedsPassword = false;
}

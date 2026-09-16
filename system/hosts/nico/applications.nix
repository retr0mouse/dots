{
  inputs,
  lib,
  ...
}: {
  imports = [inputs.soulbrainz.nixosModules.default];

  services.soulbrainz.enable = true;

  services.jellyfin = {
    enable = true;
  };

  services.plex.enable = true;
  users.users.plex.extraGroups = ["media"];

  services.radarr = {
    enable = true;
  };
  services.sonarr = {
    enable = true;
  };
  services.prowlarr = {
    enable = true;
  };

  services.qbittorrent = {
    enable = true;
  };

  fileSystems."/data" = {
    device = "/dev/disk/by-uuid/efee3c35-c283-4091-9a72-5df4cfcb2412";
    fsType = "ext4";
    options = [
      "noatime"
      "nofail"
      "x-systemd.device-timeout=5s"
    ];
  };

  systemd.tmpfiles.rules = [
    # SSD-backed application state
    "d /var/lib/postgresql 0700 postgres postgres -"
    "d /var/lib/postgresql/immich 0700 postgres postgres -"

    # HDD-backed data
    "d /data/media 2775 root media -"
    "d /data/media/movies 2775 root media -"
    "d /data/media/shows 2775 root media -"
    "d /data/music 2775 root media -"
    "d /data/downloads 2775 root media -"
    "d /data/downloads/complete 2775 root media -"
    "d /data/downloads/incomplete 2775 root media -"
    "d /data/downloads/torrents 2775 root media -"
    "d /data/downloads/finished 2775 root media -"
    "d /data/downloads/slskd 2775 root media -"
    "d /data/downloads/slskd/complete 2775 root media -"
    "d /data/downloads/slskd/incomplete 2775 root media -"
    "d /data/immich 0750 immich immich -"
    "d /data/immich/library 0750 immich immich -"
    "d /data/immich/upload 0750 immich immich -"
    "d /data/immich/thumbs 0750 immich immich -"
  ];

  systemd.services.qbittorrent.serviceConfig.UMask = "0002";
  systemd.services.radarr.serviceConfig.UMask = lib.mkForce "0002";
  systemd.services.sonarr.serviceConfig.UMask = lib.mkForce "0002";
  systemd.services.lidarr.serviceConfig.UMask = "0002";

  systemd.services.qbittorrent.after = ["data.mount"];
  systemd.services.qbittorrent.requires = ["data.mount"];

  systemd.services.radarr.after = ["data.mount"];
  systemd.services.radarr.requires = ["data.mount"];

  systemd.services.sonarr.after = ["data.mount"];
  systemd.services.sonarr.requires = ["data.mount"];

  systemd.services.jellyfin.after = ["data.mount"];
  systemd.services.jellyfin.requires = ["data.mount"];

  systemd.services.immich-server.after = ["data.mount"];
  systemd.services.immich-server.requires = ["data.mount"];

  systemd.services.navidrome.after = ["data.mount"];
  systemd.services.navidrome.requires = ["data.mount"];

  systemd.services.lidarr.after = ["data.mount"];
  systemd.services.lidarr.requires = ["data.mount"];

  systemd.services.plex.after = ["data.mount"];
  systemd.services.plex.requires = ["data.mount"];

  systemd.services.slskd = {
    after = [
      "data.mount"
      "systemd-tmpfiles-setup.service"
    ];

    requires = [
      "data.mount"
      "systemd-tmpfiles-setup.service"
    ];

    serviceConfig.UMask = "0002";
  };

  services.postgresql = {
    enable = true;
    dataDir = "/var/lib/postgresql/immich";
  };

  services.immich = {
    enable = true;

    host = "127.0.0.1";
    port = 2283;

    mediaLocation = "/data/immich/library";

    settings = {
      server.externalDomain = "https://immich.voldsoy.duckdns.org";

      ffmpeg = {
        accel = "nvenc";
        accelDecode = true;
      };
    };
  };

  users.users.immich = {
    isSystemUser = true;
    group = "immich";
    extraGroups = ["render"];
    home = "/var/lib/immich";
  };
  users.users.jellyfin.extraGroups = [
    "media"
    "render"
  ];
  users.users.radarr.extraGroups = ["media"];
  users.users.sonarr.extraGroups = ["media"];
  users.users.qbittorrent.extraGroups = ["media"];
  users.users.navidrome.extraGroups = ["media"];
  users.users.lidarr.extraGroups = ["media"];
  users.users.slskd.extraGroups = ["media"];

  users.groups.immich = {};
  users.groups.media = {};

  services.navidrome = {
    enable = true;

    settings = {
      MusicFolder = "/data/music";
      Address = "127.0.0.1";
      Port = 4533;
    };
  };

  services.lidarr = {
    enable = true;
  };

  services.vaultwarden = {
    enable = true;

    environmentFile = "/var/lib/vaultwarden/vaultwarden.env";

    config = {
      DOMAIN = "https://bitwarden.voldsoy.duckdns.org";

      SIGNUPS_ALLOWED = true;

      ROCKET_ADDRESS = "127.0.0.1";
      ROCKET_PORT = 8222;

      ROCKET_LOG = "critical";
    };
  };

  services.flaresolverr = {
    enable = true;
    port = 8191;
  };

  services.seerr = {
    enable = true;
  };

  services.slskd = {
    enable = true;

    environmentFile = "/etc/secrets/slskd.env";

    settings = {
      directories = {
        downloads = "/data/downloads/slskd/complete";
        incomplete = "/data/downloads/slskd/incomplete";
      };

      shares = {
        directories = [
          "/data/music"
        ];
      };

      web = {
        port = 5030;
        authentication = {
          disabled = true;
        };
      };
    };
  };
}

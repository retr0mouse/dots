{pkgs, ...}: {
  systemd.services.smartctl-exporter = {
    description = "Prometheus SMART exporter";

    wantedBy = ["multi-user.target"];

    serviceConfig = {
      ExecStart = "${pkgs.prometheus-smartctl-exporter}/bin/smartctl_exporter";
      Restart = "always";
      User = "root";
    };
  };

  services.uptime-kuma = {
    enable = true;
  };

  services.prometheus = {
    enable = true;

    scrapeConfigs = [
      {
        job_name = "performance";
        static_configs = [
          {
            targets = [
              "127.0.0.1:9100"
            ];
          }
        ];
      }
      {
        job_name = "smartctl";
        static_configs = [
          {
            targets = [
              "127.0.0.1:9633"
            ];
          }
        ];
      }
      {
        job_name = "fabric";
        static_configs = [
          {
            targets = [
              "127.0.0.1:25585"
            ];
          }
        ];
      }
    ];

    exporters.node = {
      enable = true;
      enabledCollectors = [
        "systemd"
        "filesystem"
        "thermal_zone"
      ];
    };
  };

  services.grafana = {
    enable = true;

    settings = {
      security = {
        secret_key = "$__file{/etc/secrets/grafana-secret-key}";
      };
      server = {
        http_addr = "127.0.0.1";
        http_port = 3000;
        domain = "grafana.voldsoy.duckdns.org";
        root_url = "https://grafana.voldsoy.duckdns.org/";
      };
    };
  };

  services.smartd = {
    enable = true;
    autodetect = true;
  };

  environment.systemPackages = with pkgs; [
    smartmontools
    prometheus-smartctl-exporter
  ];
}

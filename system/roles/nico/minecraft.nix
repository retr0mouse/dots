{
  inputs,
  pkgs,
  ...
}: {
  imports = [inputs.nix-minecraft.nixosModules.minecraft-servers];

  nixpkgs.overlays = [inputs.nix-minecraft.overlay];

  systemd.tmpfiles.rules = [
    "d /var/lib/minecraft 0750 minecraft minecraft -"
  ];

  networking.firewall = {
    allowedTCPPorts = [25565];
    allowedUDPPorts = [24454];
  };

  services.minecraft-servers = {
    dataDir = "/var/lib/minecraft";
    enable = true;
    environmentFile = "/etc/secrets/minecraft.env";
    eula = true;
    openFirewall = true;

    servers.fabric = {
      enable = true;
      jvmOpts = "-Xmx6G -Xms4G";
      package = pkgs.fabricServers.fabric.override {jre_headless = pkgs.jdk25;};

      serverProperties = {
        server-port = 25565;
        difficulty = "normal";
        max-players = 3;
        motd = "This is NixOS btw";
        online-mode = false;
        view-distance = 10;
        simulation-distance = 8;
        enable-rcon = true;
        "rcon.password" = "@RCON_PASSWORD@";
        white-list = true;
      };

      whitelist = {
        Nuacho = "f25c569a-a629-3a07-a3b6-aadbf29cc275";
        Alopopik = "2c2c1d1f-15ea-3c8f-94c3-96a87ea11c5e";
        aO_Oa = "fa25df27-d29b-3689-a4e3-1733fd9b0c40";
      };

      operators = {
        Nuacho = {
          uuid = "f25c569a-a629-3a07-a3b6-aadbf29cc275";
          level = 4;
        };
      };
      symlinks = {
        mods = pkgs.linkFarmFromDrvs "mods" (
          builtins.attrValues {
            Fabric-API = pkgs.fetchurl {
              url = "https://cdn.modrinth.com/data/P7dR8mSH/versions/lVXlbH4w/fabric-api-0.155.2%2B26.2.jar";
              sha512 = "cc56984378a27c5bcd56374d6ffbb27a45c6bf3355add2ac6be9817ccac5854362249bf9d0147eb271a70fda2716129204e240d53c9aa876a2a7861f4c7f880f";
            };
            Simple-Voice-Chat = pkgs.fetchurl {
              url = "https://cdn.modrinth.com/data/9eGKb6K1/versions/bvaEHE2T/voicechat-fabric-2.6.20%2B26.2.jar";
              sha512 = "6d9e16ef5e86b60c637797631f55c5ab3adbb8a8ee1e67f1d6b4f3c70fead800cf5d927a2f5f0eb6de5bc806088ae0d39a8ad3293c98d13936684a03c5d81336";
            };
            Chunky = pkgs.fetchurl {
              url = "https://cdn.modrinth.com/data/fALzjamp/versions/4Eotm6ov/Chunky-Fabric-1.5.3.jar";
              sha512 = "0b3amvi0lq0gkv59mi26s5wj7hghq2nh41vw2k7p7q7wn1yak5yqaxnp0bg8p7nb6vjpl8cwl82py613msawxzr58isc2ld45xzwfxq";
            };
            Distant-Horizons = pkgs.fetchurl {
              url = "https://cdn.modrinth.com/data/uCdwusMi/versions/gBf0SaV1/DistantHorizons-3.2.0-b-26.2-fabric-neoforge.jar";
              sha512 = "1r9x1aw8lcqi6wdk0qgaakz910hk5zyjjnjqy3hbccjmjf7ls5lsm9i3qvj1bbn4cjf3ax74wqkqpqr96yr3n4750iw40m0frvqbf61";
            };
            Lithium = pkgs.fetchurl {
              url = "https://cdn.modrinth.com/data/gvQqBUqZ/versions/UPNexAfy/lithium-fabric-0.25.2%2Bmc26.2.jar";
              sha512 = "181rb8szs3h704pdx1m1gbxba8mrdy6i0jbbdik0fx9qyz9k2ndpbi135sridfck52j0axfahaxqnhj3zjxkap5v8n92zjvq1v66ryv";
            };
            Krypton = pkgs.fetchurl {
              url = "https://cdn.modrinth.com/data/fQEb0iXm/versions/5WeL0Nkz/krypton-0.3.1.jar";
              sha512 = "175c7m2xnb8z261wjffgq8bms0cn41zfyjfpkza82llf0wvzlc47z2zkfxwclvadrgh9dw7i2fslpbqiz5k4qlazcx4jl00rlsazndq";
            };
            Spark = pkgs.fetchurl {
              url = "https://cdn.modrinth.com/data/l6YH9Als/versions/iYFOl6lQ/spark-1.10.173-fabric.jar";
              sha512 = "3xxphxvc0bx1qyqkyncdbp8hw1mkv6290i6lg2im7nmmjnjkwbsbhjb955fl6khpf4fav6cfy033c156qyzdsps7990gkzadjvz5jqx";
            };
            Fabric-Exporter = pkgs.fetchurl {
              url = "https://cdn.modrinth.com/data/dbVXHSlv/versions/tuPsGk8g/fabricexporter-26.2-1.0.22.jar";
              sha512 = "1q0hxjjp20mh5pihm5a5girmkjmq2zfxaijxvxy2ysmr1676pm8ia06jqs8zghx3hzvg5igxdsa8svp37fx1wbzfwp1s34hi71mqiw0";
            };
            Universal-Graves = pkgs.fetchurl {
              url = "https://cdn.modrinth.com/data/yn9u3ypm/versions/BZfhXd0q/graves-3.12.0%2B26.2.jar";
              sha512 = "09k12wyys34dwhcn4ihprv5y3vs4j69lf68zh4b79bb9pa88hv7dckz9jkk3lx60s9d7mzbhik2a3mc8r7wk3qjsx8k6cdicfq557s9";
            };
            Polymer = pkgs.fetchurl {
              url = "https://cdn.modrinth.com/data/xGdtZczs/versions/NTeStfxi/polymer-bundled-0.17.4%2B26.2.jar";
              sha512 = "3zqvk7kb8ckf5qc91pj7j9fi8znqgfnlj13g98gxnw82i6db1zgg2kwlkmx120krv7rjfv5sqxhg77yqpx3xv3mjvkjfx99zzqriwdv";
            };
          }
        );
      };
    };
  };
}

# NixOS configuration

This repository contains the NixOS and Home Manager configuration for two
`x86_64-linux` machines owned by the user `reisdro`:

| Host | Role | Purpose | Home Manager profile |
| --- | --- | --- | --- |
| `clancy` | Desktop/laptop | ASUS Zephyrus desktop environment, hybrid graphics, gaming, and a Windows VM with GPU passthrough | `user/home.nix` plus `user/hosts/clancy.nix` |
| `nico` | Server | Network gateway, DNS, reverse proxy, media applications, Minecraft, and monitoring | `user/home-server.nix` |

The configuration is built around a strict ownership rule:

- `common` contains settings that every machine should receive.
- Role modules contain settings appropriate to every desktop or every server.
- Host directories contain hardware, network identity, storage, and workloads
  specific to one machine.
- `user/common.nix` contains user configuration that is useful everywhere.
- `user/home.nix` is a hardware-neutral graphical desktop profile.
- Host-specific Home Manager layers add hardware-dependent desktop behavior.

Both NixOS configurations currently pass:

```sh
nix flake check path:. --no-build
```

The remaining evaluation warning comes from the external Soulbrainz flake,
which still refers to the deprecated `pkgs.system` attribute.

## Configuration graph

```text
flake.nix
├── clancy = mkDesktopHost "clancy"
│   ├── system/hosts/clancy/configuration.nix
│   │   ├── system/modules/desktop.nix
│   │   │   └── system/modules/common.nix
│   │   ├── hardware-configuration.nix
│   │   ├── vfio.nix
│   │   ├── looking-glass.nix
│   │   └── nixos-hardware: asus-zephyrus-ga503
│   └── user/home.nix
│       ├── user/common.nix
│       ├── graphical program modules
│       └── user/hosts/clancy.nix
└── nico = mkServerHost "nico"
    ├── system/hosts/nico/configuration.nix
    │   ├── system/modules/server.nix
    │   │   └── system/modules/common.nix
    │   ├── hardware-configuration.nix
    │   ├── networking.nix
    │   ├── applications.nix
    │   ├── minecraft.nix
    │   └── monitoring.nix
    └── user/home-server.nix
        └── user/common.nix
```

`mkDesktopHost` also loads Home Manager, the Noctalia greeter module, and the
local `hyprmoncfg` overlay. `mkServerHost` loads Home Manager with the smaller
server user profile.

## Repository layout

```text
.
├── flake.nix                       # Inputs, host constructors, host outputs
├── flake.lock                      # Pinned input revisions
├── packages/
│   └── hyprmoncfg.nix              # Local package definition
├── scripts/                        # Hardware-neutral user scripts
├── system/
│   ├── modules/
│   │   ├── common.nix              # Shared NixOS baseline
│   │   ├── desktop.nix             # Reusable graphical-machine role
│   │   └── server.nix              # Reusable server role
│   └── hosts/
│       ├── clancy/                 # Clancy hardware, VFIO, Looking Glass
│       └── nico/                   # Nico hardware and server workloads
├── user/
│   ├── common.nix                  # Shared Home Manager baseline
│   ├── home.nix                    # Reusable graphical desktop profile
│   ├── home-server.nix             # Server user profile
│   ├── hosts/clancy.nix            # Clancy-only Home Manager additions
│   ├── modules/                    # Program-specific Home Manager modules
│   ├── programs.nix                # Graphical desktop package collection
│   └── scripts.nix                 # Shared desktop script packages
└── walls/                           # Wallpapers
```

The generated `hardware-configuration.nix` files should remain host-local and
should not be manually generalized into role modules.

## Flake inputs

The main inputs are:

- `nixpkgs` and Home Manager on the NixOS 26.05 release branch.
- `nixpkgs-unstable`, currently declared but not used directly.
- `nixos-hardware` for Clancy's ASUS Zephyrus GA503 hardware module.
- `xremap-flake` for desktop key remapping.
- `wlctl` for the desktop network TUI.
- `noctalia-greeter` for the desktop display manager.
- `nix-minecraft` for Nico's declarative Fabric server and package overlay.
- `soulbrainz` for Nico's ListenBrainz-to-slskd workflow.
- A pinned Looking Glass source revision with submodules for Clancy's custom
  client build.

The architecture and username are currently fixed in `flake.nix` as
`x86_64-linux` and `reisdro`.

## Shared system roles

### Common

`system/modules/common.nix` is imported by both role modules. It owns:

- Flakes and `nix-command` support.
- Unfree package permission.
- Weekly garbage collection of generations older than three days.
- systemd-boot on EFI, a one-second boot menu, and `boot.shell_on_fail`.
- Tallinn time, Canadian English locale, and British `LC_TIME`.
- D-Bus, periodic trim, and systemd time synchronization.
- The normal `reisdro` user, wheel membership, and Zsh as the login shell.
- `nix-ld` for running dynamically linked, non-Nix executables.

It intentionally does not enable graphical services, hardware-specific
features, NetworkManager privileges, or an SSH daemon.

### Desktop

`system/modules/desktop.nix` adds the reusable graphical-machine role:

- Plymouth boot splash.
- Hyprland with UWSM, XWayland, Noctalia greeter, and XDG portals.
- NetworkManager using the `wpa_supplicant` Wi-Fi backend.
- PipeWire audio, Bluetooth, removable-media services, polkit, and rtkit.
- Steam and Gamescope without opening Remote Play or dedicated-server ports.
- Desktop fonts and Estonian/US plus Russian keyboard layouts.
- xremap navigation chords based on Caps Lock.
- `input`, `networkmanager`, `video`, and `render` user groups.

The role contains no Clancy PCI addresses, VM configuration, laptop power
widgets, or application-specific firewall openings.

### Server

`system/modules/server.nix` imports the common baseline and enables OpenSSH
with password authentication disabled. Desktop-only hosts do not run an SSH
daemon through this configuration.

## Clancy

Clancy is an ASUS Zephyrus GA503 laptop with an AMD integrated GPU and NVIDIA
discrete GPU.

### Hardware and desktop behavior

`system/hosts/clancy/configuration.nix` owns:

- Hostname `clancy`.
- ASUS hardware support, `asusd`, power profiles, lid behavior, and touchpad
  natural scrolling.
- AMD and NVIDIA drivers with PRIME offload.
- AMD PCI bus `06:00.0` and NVIDIA PCI bus `01:00.0`.
- A stable `/dev/dri/amd-igpu` udev symlink used by the user session.
- A WireGuard client at `10.10.0.6`, using Nico at `10.10.0.1` for DNS and
  access to the VPN and home LAN.

The host-specific Home Manager layer, `user/hosts/clancy.nix`, enables the
Waybar battery, backlight, power-profile, iGPU, and dGPU widgets. It also owns
the matching helper scripts and forces Hyprland and selected graphical user
services onto Mesa/AMD where required.

### Windows VM and Looking Glass

`vfio.nix` enables libvirt, virt-manager, swtpm, SPICE USB redirection, and
ASUS Supergfxd VFIO support. The user receives `libvirtd` and `kvm` group
membership only on this host.

`looking-glass.nix`:

- Builds the pinned development Looking Glass client.
- Loads KVMFR with a 128 MiB static buffer at `/dev/kvmfr0`.
- Gives `reisdro:kvm` access to that device.
- Extends QEMU's device ACL for KVMFR and VFIO.
- Installs the Clancy-only `start-vm` command.

`start-vm` manages the libvirt VM named `windows11` and assumes the RTX 3060
is at PCI address `0000:01:00.0`. Before starting the VM it refuses to detach
the GPU while Linux applications are using it. When Looking Glass closes, it
requests a clean guest shutdown and verifies that the GPU rebinds to the
NVIDIA driver. These assumptions must be reviewed if the VM name or PCI
topology changes.

## Nico

Nico is a headless server with legacy NVIDIA graphics support, zram, disabled
suspend/hibernate, and a 500 MiB journal size cap. Its configuration
is split into four substantial host-local modules.

### Networking and ingress

`system/hosts/nico/networking.nix` owns:

- Hostname `nico` and NetworkManager Ethernet management.
- IPv4 forwarding and WireGuard server address `10.10.0.1/24`.
- Forwarding from WireGuard clients to the `192.168.0.0/24` LAN.
- DuckDNS updates and wildcard ACME certificates for
  `*.voldsoy.duckdns.org`.
- Nginx TLS termination and reverse proxies.
- fail2ban.
- Unbound on `127.0.0.1:5335` behind Pi-hole FTL.
- Pi-hole's web UI on `127.0.0.1:8081` and local DNS overrides pointing the
  service domains to `192.168.0.251`.

The reverse-proxy routes are:

| Public hostname | Local service |
| --- | --- |
| `immich.voldsoy.duckdns.org` | `127.0.0.1:2283` |
| `pihole.voldsoy.duckdns.org` | `127.0.0.1:8081` |
| `jellyfin.voldsoy.duckdns.org` | `127.0.0.1:8096` |
| `plex.voldsoy.duckdns.org` | `127.0.0.1:32400` |
| `qbittorrent.voldsoy.duckdns.org` | `127.0.0.1:8080` |
| `prowlarr.voldsoy.duckdns.org` | `127.0.0.1:9696` |
| `movies.voldsoy.duckdns.org` | `127.0.0.1:7878` |
| `shows.voldsoy.duckdns.org` | `127.0.0.1:8989` |
| `lidarr.voldsoy.duckdns.org` | `127.0.0.1:8686` |
| `music.voldsoy.duckdns.org` | `127.0.0.1:4533` |
| `uptime-kuma.voldsoy.duckdns.org` | `127.0.0.1:3001` |
| `grafana.voldsoy.duckdns.org` | `127.0.0.1:3000` |
| `bitwarden.voldsoy.duckdns.org` | `127.0.0.1:8222` |
| `seerr.voldsoy.duckdns.org` | `127.0.0.1:5055` |
| `slskd.voldsoy.duckdns.org` | `127.0.0.1:5030` |

Unknown Nginx hosts receive status 444.

The firewall explicitly allows HTTPS and WireGuard. Minecraft owns its own
game and voice-chat ports. `lo`, `enp3s0`, and `wg0` are trusted interfaces,
so services are reachable from those interfaces even when they are not in the
global allow lists.

### Storage and applications

`system/hosts/nico/applications.nix` mounts the bulk-data disk at `/data` by
UUID with `noatime`, `nofail`, and a five-second device timeout. Services that
consume bulk data require `data.mount` and therefore do not start against an
unmounted directory.

Important locations are:

| Data | Location |
| --- | --- |
| Movies and shows | `/data/media/movies`, `/data/media/shows` |
| Music | `/data/music` |
| Downloads | `/data/downloads` |
| Immich library | `/data/immich/library` |
| Immich/PostgreSQL state | `/var/lib/postgresql/immich` |
| Minecraft state | `/var/lib/minecraft` |

The `media` group and service-specific UMask settings allow the download and
media applications to share files.

Hosted applications include:

- Jellyfin for video media.
- Plex for the already-claimed music library only. Plex libraries are managed
  in Plex itself; no movie or show library is declared here.
- Radarr, Sonarr, Prowlarr, qBittorrent, Lidarr, and FlareSolverr.
- Immich with PostgreSQL and NVIDIA NVENC acceleration.
- Navidrome using `/data/music`.
- slskd, Seerr, Vaultwarden, and Soulbrainz.

### Minecraft

`system/hosts/nico/minecraft.nix` owns the nix-minecraft module and overlay,
the Fabric server, its firewall ports, runtime directory, and pinned Modrinth
mods.

The server currently:

- Uses JDK 25 with 4–6 GiB of heap.
- Listens on TCP 25565 with Simple Voice Chat on UDP 24454.
- Runs offline mode with a whitelist and a maximum of three players.
- Enables RCON and substitutes its password at runtime.
- Includes Fabric API, Simple Voice Chat, Chunky, Distant Horizons, Lithium,
  Krypton, Spark, Fabric Exporter, Universal Graves, and Polymer.

Because nix-minecraft firewall automation is enabled and RCON is enabled, its
configured RCON port may also be opened by the module. Treat the RCON password
as a network credential and rotate it if exposed.

### Monitoring

`system/hosts/nico/monitoring.nix` provides:

- Uptime Kuma.
- Prometheus scraping node metrics, SMART metrics, and Fabric metrics.
- The Prometheus node exporter.
- A root-run SMART exporter and `smartd` disk monitoring.
- Grafana bound to localhost and published through Nginx.

## Home Manager

### Shared user profile

`user/common.nix` is imported on both machines. It provides:

- Git and Delta.
- Zsh with Oh My Zsh.
- Neovim, language servers, Treesitter, LSP, completion, and the
  Lua configuration under `user/modules/neovim/lua`.
- SSH client defaults.
- Common terminal tools: `btop`, `fzf`, `gh`, `jq`, `tree`, and `yazi`.
- Home Manager itself.

### Reusable graphical profile

`user/home.nix` is intended to work on any graphical desktop or laptop. It
provides Hyprland, Waybar, Kitty, Brave, Rofi, Hyprlock, notification and
clipboard services, GTK/cursor settings, Wayland environment variables, and
the graphical package collection in `user/programs.nix`.

Waybar's hardware-dependent widgets are disabled by default. Host layers can
enable these options independently:

```nix
dotfiles.waybar = {
  showBacklight = true;
  showBattery = true;
  showDiscreteGpu = true;
  showIntegratedGpu = true;
  showPowerProfile = true;
};
```

If a host enables a custom widget, its host-specific Home Manager layer must
also provide the command used by that widget.

### Server user profile

`user/home-server.nix` adds JDK 25 and `mcrcon` to the shared user profile. It
does not import graphical modules or desktop applications.

Do not change either Home Manager `stateVersion` merely to match the current
release. They record the first-deploy compatibility baseline:

- Graphical profile: `24.11`
- Server profile: `25.11`

The same rule applies to each host's NixOS `system.stateVersion`, currently
`25.11`.

## Secrets and machine-local files

Secrets are deliberately referenced by absolute paths and are not stored in
Git or copied into the Nix store.

| Host | Path | Used by |
| --- | --- | --- |
| Clancy | `/etc/wireguard/privatekey` | WireGuard client |
| Nico | `/etc/wireguard/privatekey` | WireGuard server |
| Nico | `/etc/secrets/duckdns-acme-env` | ACME DNS challenge |
| Nico | `/etc/secrets/duckdns-token` | DuckDNS updater |
| Nico | `/etc/secrets/grafana-secret-key` | Grafana secret key |
| Nico | `/etc/secrets/slskd.env` | slskd credentials/configuration |
| Nico | `/var/lib/vaultwarden/vaultwarden.env` | Vaultwarden environment |
| Nico | `/etc/secrets/minecraft.env` | Minecraft RCON password |

`/etc/secrets/minecraft.env` must contain:

```text
RCON_PASSWORD=<a-strong-password>
```

Create required secret files on the target host before switching to a
configuration that consumes them. Use restrictive ownership and permissions;
root ownership with mode `0600` is appropriate for systemd environment files
that do not need direct service-user access.

Never commit real values, copy them into this repository, or interpolate them
directly into Nix strings. If a secret has ever been committed or built into a
Nix derivation, rotate it even if Git history is later rewritten.

## Common operations

Run commands from this repository or use the `rebuild` Zsh alias.

Evaluate every host without building:

```sh
nix flake check path:. --no-build
```

Using `path:.` includes new untracked files during development. A normal Git
flake reference includes only files known to Git.

Build a host without activating it:

```sh
sudo nixos-rebuild build --flake .#clancy
sudo nixos-rebuild build --flake .#nico
```

Activate the configuration for the current host:

```sh
sudo nixos-rebuild switch --flake .#$(hostname)
```

Format Nix files:

```sh
alejandra .
```

Update locked inputs deliberately and review the result before rebuilding:

```sh
nix flake update
nix flake check path:. --no-build
```

Home Manager uses global NixOS packages, installs user packages through the
NixOS integration, and moves colliding managed files to a `.backup` suffix.

## Adding another host

For a new desktop:

1. Add `system/hosts/<hostname>/configuration.nix` and its generated hardware
   configuration.
2. Import `system/modules/desktop.nix` from the host configuration.
3. Add `<hostname> = mkDesktopHost "<hostname>";` to `flake.nix`.
4. Add `user/hosts/<hostname>.nix` only for genuine host-specific Home Manager
   behavior, then import it through `home-manager.users.${user}.imports`.
5. Enable only the Waybar hardware capabilities supported by that machine and
   provide their helper commands.

For a new server:

1. Add the host and hardware configuration under `system/hosts/<hostname>`.
2. Import `system/modules/server.nix`.
3. Keep workloads in a few cohesive host-local modules rather than adding them
   to `server.nix`.
4. Add `<hostname> = mkServerHost "<hostname>";` to `flake.nix`.

Promote a setting upward only when it is genuinely shared by every consumer of
that layer. In particular, hardware IDs, disk UUIDs, VM names, secrets, and
service workloads belong to hosts; graphical programs belong to the desktop
profile; and SSH daemon policy belongs to the server role.

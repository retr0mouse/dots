# NixOS configuration

This is a declarative NixOS and Home Manager configuration built around two
logical machine roles:

- **Clancy** is the desktop role.
- **Nico** is the server role.

Those names describe responsibilities, not permanent pieces of hardware.
Replacing a laptop should mean moving the Clancy role to the new machine and
updating only its hardware-specific layer. The old machine can become Nico, or
another role, without dragging desktop assumptions into the server
configuration.

## Design principles

### Configure roles, not devices

Most configuration belongs to a reusable role. A desktop should receive the
desktop environment, audio, networking, applications, and user session. A
server should receive remote administration and hosted services without
inheriting graphical or laptop-specific behavior.

Only details that genuinely describe one physical installation belong to the
host layer. Examples include:

- Generated hardware configuration
- Disk UUIDs
- GPU bus addresses and driver quirks
- WireGuard identity and network addresses
- VM device passthrough
- Host-specific mounts and service data paths

This keeps hardware replacement local: preserve the role, replace the host
details.

### Keep shared layers genuinely shared

The common system layer is intentionally small. It contains baseline NixOS
policy that is appropriate everywhere, such as locale, time synchronization,
garbage collection, the login shell, and core Nix settings.

Desktop behavior belongs to the desktop role. Server behavior belongs to the
server role. Workloads that run on only one server stay with that server rather
than becoming part of the meaning of “server.”

The same rule applies to Home Manager:

- Shared terminal and editor configuration is available everywhere.
- The graphical profile is reusable across desktop PCs and laptops.
- Hardware-dependent widgets and scripts are opt-in host additions.

### Organize by ownership

The important boundary is who should receive a setting:

| Layer | Owns |
| --- | --- |
| Common system | Baseline policy for every machine |
| Desktop role | Graphical services and capabilities expected on every desktop |
| Server role | Server-wide policy such as key-based SSH access |
| Host system | Hardware, storage, networking identity, and host-only workloads |
| Common user | Shell, Git, editor, SSH client, and shared CLI tools |
| Desktop user | Graphical applications and desktop-session services |
| Host user | Hardware-specific desktop behavior and helper scripts |
| Program module | Configuration that belongs to one program or cohesive service |

If a setting contains a PCI address, disk UUID, VM name, or machine-specific
device path, it is almost certainly host configuration. If it starts a media
server, game server, or monitoring stack on only one host, it is a host
workload rather than generic server policy.

## Desktop role

Clancy provides a Wayland desktop centered around Hyprland. The reusable
desktop role includes:

- Hyprland with UWSM and XWayland support
- A graphical greeter and XDG desktop portals
- PipeWire audio
- NetworkManager and Wi-Fi support
- Bluetooth and removable-media integration
- Polkit and realtime scheduling support
- Steam and Gamescope without automatically opening gaming firewall ports
- Shared fonts and multilingual keyboard layouts
- Keyboard remapping through xremap

The Home Manager desktop profile adds:

- Hyprland user configuration
- Waybar
- Kitty
- Brave and graphical default applications
- Rofi and Hyprlock
- Notifications and clipboard history
- Wallpaper and monitor-management tools
- Desktop development, communication, productivity, media, and gaming
  applications

### Hardware capabilities are opt-in

The graphical profile is intended to work on either a desktop PC or a laptop.
It does not assume that every machine has a battery, backlight, power profiles,
or multiple GPUs.

Waybar exposes independent capability switches for:

- Battery status
- Backlight control
- Power profiles
- Integrated GPU usage
- Discrete GPU usage

A host enables only the widgets supported by its hardware and supplies any
matching helper commands. This prevents a future desktop from inheriting
broken laptop widgets or hard-coded GPU paths.

### Virtualization and GPU passthrough

The desktop role supports a host-specific Windows virtualization layer using:

- libvirt and virt-manager
- VFIO GPU passthrough
- swtpm for Windows 11
- Looking Glass with KVMFR
- A guarded VM launcher that checks whether the GPU is in use, starts the VM,
  opens Looking Glass, requests a clean shutdown, and verifies that the GPU
  returns to Linux

The generic desktop role does not know the VM name, PCI topology, GPU driver,
or KVMFR ownership rules. Those remain in Clancy’s host layer and must be
reviewed whenever the desktop hardware changes.

## Server role

Nico is a headless service host. The reusable server role adds key-based SSH
administration to the common baseline. It does not define what applications a
server must run; those remain host workloads.

The server host is composed from several cohesive workload capabilities.

### Networking and ingress

- WireGuard server and LAN forwarding
- Stateful firewall policy
- Dynamic DNS
- Automated wildcard TLS certificates
- Nginx reverse proxy and TLS termination
- fail2ban
- Pi-hole backed by Unbound
- Local DNS records for hosted services

Public ingress is kept at the reverse proxy where possible. Applications bind
to localhost and are exposed through named HTTPS virtual hosts. Game and VPN
ports are owned by the modules that require them rather than by generic server
policy.

### Storage and applications

Bulk data is mounted separately from application state. Services that depend
on bulk storage explicitly require the mount, preventing them from writing
into an empty mount point when the disk is unavailable.

A shared media group and deliberate UMask settings allow downloaders and media
managers to cooperate without making all service data globally writable.

The hosted application stack includes:

- Jellyfin for video
- Plex for music
- Immich for photos and video, with hardware-accelerated transcoding
- Navidrome and Lidarr for music
- Radarr and Sonarr for video library management
- Prowlarr, qBittorrent, and FlareSolverr
- slskd and Soulbrainz
- Seerr
- Vaultwarden

Plex is intentionally used only for music. Jellyfin remains the video-media
service. Plex library selection is managed by Plex itself rather than encoded
as movie or show configuration here.

### Minecraft

The Minecraft workload uses nix-minecraft to provide a declarative Fabric
server, pinned mods, firewall integration, resource limits, whitelist, and
operators.

The server enables RCON, but its password is substituted from a machine-local
environment file at runtime. The password is never written directly into Nix
source or a Nix store derivation.

### Monitoring

The monitoring stack combines:

- Prometheus
- Node, SMART, and Minecraft metrics
- Grafana
- Uptime Kuma
- smartd disk monitoring

Monitoring services bind locally where appropriate and use the same reverse
proxy and TLS boundary as the application stack.

## User environment

The shared Home Manager profile keeps the interactive environment consistent
across desktop and server machines.

Each host selects the username that receives this profile. The profile derives
the account name and home directory from that choice instead of assuming a
fixed username, so moving a role to new hardware does not require preserving
the old machine's account name.

The shared profile includes:

- Zsh and common aliases
- Git and Delta
- Neovim with LSP, completion, Treesitter, navigation, diagnostics, and
  formatting integration
- SSH client defaults
- Common terminal utilities

The server user profile stays intentionally small and adds only tools useful
for administering its workloads. It does not import graphical modules.

Home Manager and NixOS `stateVersion` values are compatibility baselines, not
release channels. They should not be changed merely because the inputs were
updated.

## Secrets

Secrets are machine state, not configuration source. The repository stores
only absolute paths or runtime placeholders; actual values live on the target
machine outside Git and outside the Nix store.

Secret-bearing integrations include:

- WireGuard private keys
- Dynamic DNS and ACME credentials
- Grafana’s secret key
- Vaultwarden’s environment
- slskd credentials
- Minecraft’s RCON password

The Minecraft environment file uses this format:

```text
RCON_PASSWORD=<a-strong-password>
```

Secret files must exist before activating a configuration that consumes them.
Use restrictive ownership and permissions. Never copy real values into this
repository or interpolate them directly into Nix strings.

If a secret has ever been committed or included in a Nix derivation, rotate
it. Removing it from the latest Git revision does not remove it from Git
history, existing clones, or old Nix store paths.

## Working with the configuration

Evaluate all hosts without building them:

```sh
nix flake check path:. --no-build
```

Using `path:.` includes new untracked files during development. A Git-backed
flake reference includes only files known to Git.

Build a role without activating it:

```sh
sudo nixos-rebuild build --flake .#clancy
sudo nixos-rebuild build --flake .#nico
```

Activate the role matching the current hostname:

```sh
sudo nixos-rebuild switch --flake .#$(hostname)
```

Format Nix files:

```sh
alejandra .
```

Update inputs deliberately, inspect the lock-file changes, and evaluate every
host before switching:

```sh
nix flake update
nix flake check path:. --no-build
```

## Replacing hardware or adding roles

When replacing a desktop or server, keep the logical role and change only the
host-specific facts:

1. Generate or update the hardware configuration.
2. Review disks, network interfaces, GPU identifiers, and driver choices.
3. Recreate required machine-local secrets.
4. Reapply only the host-specific Home Manager capabilities supported by the
   new hardware.
5. Build and verify the role before switching.

When adding another machine, start with the smallest appropriate role and add
host-local workload modules. Do not expand a shared layer merely to avoid one
extra import.

The test for promoting a setting is simple: every consumer of the higher layer
must genuinely want it. If that is uncertain, keep the setting closer to the
host or program that owns it.

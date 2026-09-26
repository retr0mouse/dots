# NixOS configuration

This is a declarative NixOS and Home Manager configuration built around
transferable logical roles:

- **Clancy** is the desktop role.
- **Nico** is the server role.

Those names describe responsibilities and network identities, not permanent
pieces of hardware. A deployment explicitly assigns a role to a physical
machine. Replacing a laptop means adding the new machine facts and changing
that assignment; the Clancy role itself stays unchanged. The old machine can
then become Nico, Backup, or another role.

## Design principles

### Compose roles and machines

The configuration distinguishes two independent concepts:

- A **role** is a transferable logical identity and complete job, such as the
  Clancy desktop or Nico server.
- A **machine** is one physical installation such as the current Asus laptop.

Roles own their system behavior, user environment, applications, workloads,
hostname, and network identity. Machines provide hardware and installation
facts.

Only details that genuinely describe one physical installation belong to the
machine layer. Examples include:

- Generated hardware configuration
- Disk UUIDs
- Network interface names
- GPU bus addresses and driver quirks
- VM device passthrough
- Hardware-specific mounts
- Lid, battery, backlight, and power behavior

Conversely, a hostname, WireGuard identity, DNS name, media stack, or Minecraft
server follows its named role to replacement hardware.

### Keep shared layers genuinely shared

The common system layer is intentionally small. It contains baseline NixOS
policy that is appropriate everywhere, such as locale, time synchronization,
garbage collection, the login shell, and core Nix settings.

Desktop behavior belongs directly to Clancy, and server behavior belongs
directly to Nico. A future Backup role will own its own behavior rather than
inheriting Nico's media or game services.

The same rule applies to Home Manager:

- Shared terminal and editor configuration is available everywhere.
- Clancy's graphical configuration moves with the role.
- Hardware-dependent widgets and scripts follow machine capabilities.

### Organize by ownership

The important boundary is who should receive a setting:

| Layer | Owns |
| --- | --- |
| Common system | Baseline policy for every deployment |
| Named role | System behavior, user environment, identity, and workloads |
| Physical machine | Hardware, storage devices, drivers, and installation quirks |
| Common user | Shell, Git, editor, SSH client, and shared CLI tools |
| Role-machine integration | Hardware-specific behavior needed only for one role |
| Program module | Configuration that belongs to one program or cohesive service |

If a setting contains a PCI address, disk UUID, VM name, or machine-specific
device path, it is almost certainly machine configuration. A workload that
defines what Nico does belongs directly to Nico.

### Deployment inventory

`flake.nix` is the single composition point. It declares named roles, physical
machines, and active deployments. The current assignments are:

```text
clancy = Clancy role + asus-ga503 machine
nico   = Nico role   + msi-gp62m-7rdx machine
```

NixOS and Home Manager are composed in parallel from the same assignment. The
machine publishes a small typed hardware-capability set, and Clancy's Home
Manager configuration reads it through `osConfig`; battery, backlight,
power-profile, and GPU widgets therefore do not need to be declared twice.

The inventory also supports machine integrations selected by role. This
handles settings that are physical facts but only make sense in one use: the
MSI GP62M 7RDX's no-sleep policy is loaded only when it provides Nico, while
the Asus VM, desktop helpers, and renderer workarounds are loaded only when it
provides Clancy. Reassigning the hardware does not drag its previous job along
with it.

The relevant source layout is:

```text
system/common.nix
system/roles/             complete Clancy and Nico system behavior
system/features/          reusable opt-in hardware and service capabilities
system/machines/          physical hardware and installation facts
user/common.nix
user/roles/               complete user behavior for Clancy and Nico
user/machines/            exceptional machine-specific user integration
user/modules/             one program or cohesive service per module
```

## Clancy desktop role

Clancy is a Wayland desktop role centered around Hyprland. It includes:

- Hyprland with UWSM and XWayland support
- A graphical greeter and XDG desktop portals
- PipeWire audio
- NetworkManager and Wi-Fi support
- Bluetooth and removable-media integration
- Polkit and realtime scheduling support
- Steam and Gamescope without automatically opening gaming firewall ports
- Shared fonts and multilingual keyboard layouts
- Keyboard remapping through xremap

Clancy's Home Manager configuration adds:

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

The Clancy role is intended to work on either a desktop PC or a laptop. It does
not assume that every machine has a battery, backlight, power profiles, or
multiple GPUs.

Waybar exposes independent capability switches for:

- Battery status
- Backlight control
- Power profiles
- Integrated GPU usage
- Discrete GPU usage

The assigned machine publishes only the capabilities supported by its hardware.
Home Manager derives the widgets from those capabilities. This prevents a
future Framework or desktop PC from inheriting Asus battery widgets, Nvidia
scripts, or hard-coded GPU paths.

### Virtualization and GPU passthrough

The current Asus machine provides a hardware-specific Windows virtualization
layer using:

- libvirt and virt-manager
- VFIO GPU passthrough
- swtpm for Windows 11
- Looking Glass with KVMFR
- A guarded VM launcher that checks whether the GPU is in use, starts the VM,
  opens Looking Glass, requests a clean shutdown, and verifies that the GPU
  returns to Linux

The core Clancy role does not know the VM name, PCI topology, GPU driver, or
KVMFR ownership rules. Those remain in the Asus-and-Clancy integration and do
not follow Clancy onto incompatible hardware.

## Nico server role

Nico is a headless service role. It adds key-based SSH administration and its
server policy to the common baseline.

The Nico role is composed from several cohesive workload capabilities.

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

The common Home Manager layer keeps the interactive environment consistent
across roles.

Each deployment selects the username that receives its composed Home Manager
configuration. The common layer derives the account name and home directory
from that choice instead of embedding it throughout the modules.

The common layer includes:

- Zsh and common aliases
- Git and Delta
- Neovim with LSP, completion, Treesitter, navigation, diagnostics, and
  formatting integration
- SSH client defaults
- Common terminal utilities

Nico's user role stays intentionally small and does not import graphical
modules. Its Minecraft administration tools belong to Nico, not to a future
Backup role.

Home Manager and NixOS `stateVersion` values are compatibility baselines, not
release channels. They should not be changed merely because the inputs were
updated.

## Secrets

Plaintext secrets are deployment state, not configuration source. The
repository stores only absolute paths or runtime placeholders; actual values
live on the target machine outside Git and outside the Nix store. Role identity
secrets such as WireGuard keys must move deliberately during a role transfer,
while hardware-bound secrets such as disk-encryption keys remain with the
physical machine.

Secret-bearing integrations include:

- WireGuard private keys
- Home-network identifiers used by the automatic WireGuard policy
- Dynamic DNS and ACME credentials
- Grafana’s secret key
- Vaultwarden’s environment
- slskd credentials
- Minecraft’s RCON password

The Minecraft environment file uses this format:

```text
RCON_PASSWORD=<a-strong-password>
```

The Clancy WireGuard policy reads `/etc/secrets/wireguard-home-network.env`:

```text
WIREGUARD_HOME_WIFI_UUIDS="<uuid> <another-uuid>"
WIREGUARD_HOME_GATEWAY_MAC="<gateway-mac>"
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

Build an active deployment without activating it:

```sh
sudo nixos-rebuild build --flake .#clancy
sudo nixos-rebuild build --flake .#nico
```

Activate the deployment matching the current logical hostname:

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

To replace the machine currently providing a role:

1. Add a new `system/machines/<machine>/` directory with generated hardware
   configuration and only the new machine's physical facts.
2. Add the machine to `machines` in `flake.nix`.
3. Add a temporary deployment such as `clancy-next` using the existing Clancy
   role, the new machine, and `activateIdentity = false`.
4. Build and test the staged deployment. Its logical WireGuard, DuckDNS, ACME,
   nginx, and related UI identity controls remain inactive, so it can coexist
   with the active role.
5. Restore user and service state separately; declarative configuration does
   not move mutable data.
6. Stop the old role, change the active deployment's machine assignment, and
   transfer its secrets and network identity.
7. Rebuild the normal role output and only then repurpose the old machine.

Role contracts are checked during evaluation where practical. For example,
Nico requires its assigned machine to provide the stable `/data` filesystem;
the disk device and filesystem details still remain in the machine layer. The
inventory also rejects multiple deployments that simultaneously claim the same
active role identity; staged replacements must keep `activateIdentity = false`.

A future Backup role should import its own backup repository capabilities. It
will receive the common system and user layers automatically, but must not
inherit Nico's media, Minecraft, DNS, or ingress workloads. Any behavior that
multiple roles genuinely share can be extracted into an opt-in feature.

The test for promoting a setting is simple: every consumer of the higher layer
must genuinely want it. If that is uncertain, keep the setting closer to the
role, machine, or program that owns it.

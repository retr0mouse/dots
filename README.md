# NixOS configuration

This repository defines two explicit NixOS hosts. It is intentionally
host-oriented: each host directory contains its complete job and its current
hardware facts. A little repetition is preferred over indirection that makes a
setting difficult to find.

| Flake output | Current hardware | Responsibility |
| --- | --- | --- |
| `clancy` | Asus GA503 laptop | Hyprland desktop, personal applications, WireGuard client, and Windows VM passthrough |
| `nico` | MSI GP62M 7RDX laptop | Home server, storage-backed applications, Minecraft, DNS, VPN, ingress, and monitoring |

The Raspberry Pi TV configuration was retired. That device now runs LibreELEC
and is not managed by this repository.

## Repository layout

```text
flake.nix                    explicit definitions of clancy and nico
hosts/
  clancy/
    default.nix              complete Clancy import list
    hardware*.nix            current installation and hardware facts
    desktop.nix              system-wide graphical desktop
    networking.nix           WireGuard client and its home/away policy
    graphics.nix             Asus GPU and PRIME configuration
    vfio.nix                 virtualization and passthrough
    looking-glass.nix        Looking Glass system integration
    home.nix                 Clancy Home Manager composition
    home-hardware.nix        Asus-specific user-session integration
    packages.nix             Clancy's main user package list
    home/                     Clancy-only application modules and assets
    scripts/                  Clancy-only helper scripts
  nico/
    default.nix              complete Nico import list
    hardware*.nix            current installation and hardware facts
    server.nix               SSH and base server policy
    applications.nix         hosted applications and storage dependencies
    minecraft.nix            Minecraft server
    monitoring.nix           Prometheus, Grafana, Uptime Kuma, and SMART
    networking.nix           firewall, VPN, DNS, TLS, and reverse proxy
    home.nix                 small server-side Home Manager profile
modules/
  nixos/                     settings genuinely shared by both hosts
  home/                      terminal/editor settings shared by both users
packages/                    custom Nix packages
scripts/check                repository evaluation and build entrypoint
docs/                        secrets and recovery runbooks
```

`hosts/<name>/default.nix` is the table of contents for that machine. Start
there when tracing where a setting originates.

## Where a setting belongs

- Put a setting under `hosts/clancy/` when only Clancy needs it.
- Put a setting under `hosts/nico/` when only Nico needs it.
- Put disk UUIDs, PCI addresses, interface names, device paths, and generated
  hardware configuration in the affected host's hardware files.
- Put a setting under `modules/` only when both current hosts genuinely want
  the same behavior.
- Keep a large cohesive service in its own file; small service additions can
  stay in the closest existing topical file.
- Keep user applications in Home Manager and system services, drivers, boot
  policy, and privileged integration in NixOS.

There is no role inventory, machine registry, feature-flag framework, or
automatic profile discovery. `flake.nix` lists the two configurations
directly, and the imports in each host make their composition explicit.

## Clancy

Clancy is a Wayland desktop centered on Hyprland. It includes:

- Noctalia greeter, QuickShell bar, SwayNC, Rofi, and session controls
- NetworkManager, PipeWire, Bluetooth, removable media, and power management
- Steam, Gamescope, desktop applications, and development tools
- Asus/NVIDIA PRIME integration
- libvirt, VFIO, KVMFR, and Looking Glass for the existing Windows VM
- A WireGuard client with guarded automatic home/away behavior

QuickShell is the only configured desktop bar. Asus-specific GPU scripts,
backlight devices, touchpad controls, and renderer workarounds are kept beside
the Clancy host instead of being hidden behind generic hardware flags.

Clancy's NixOS `system.stateVersion` is `25.11`; its Home Manager
`home.stateVersion` is `24.11`. These are compatibility baselines and must not
be updated merely because the flake inputs are newer.

## Nico

Nico remains one complete server. Its topical files are subdivisions for
readability, not independently enabled features.

The current workload includes:

- Key-only SSH administration
- WireGuard, DuckDNS, ACME, nginx, fail2ban, Pi-hole, and Unbound
- Immich, Jellyfin, Plex, Navidrome, Lidarr, Radarr, Sonarr, Prowlarr,
  qBittorrent, FlareSolverr, slskd, Soulbrainz, Seerr, and Vaultwarden
- A declarative Fabric Minecraft server
- Prometheus, Grafana, Uptime Kuma, smartd, and SMART metrics

Security-sensitive current settings are deliberately visible rather than
hidden behind a generic server profile:

- Minecraft offline mode is temporarily intentional. Its whitelist is not a
  substitute for account authentication. RCON is enabled and allowed by the
  host firewall, but is not intended to be forwarded by the router.
- slskd web authentication is disabled and Vaultwarden registration is open.
  Both rely on the current LAN/VPN-only ingress boundary and must be reviewed
  before either service is made public.
- Router forwarding describes the current IPv4 boundary. Publicly routed IPv6
  must be checked separately rather than assumed to follow NAT forwarding.

Bulk application data is mounted at `/data`. Services using it explicitly
require `data.mount`, preventing accidental writes into an empty mount point.
The generated hardware configuration and `/data` filesystem UUID are part of
Nico because they describe its current installation.

Only the router's WireGuard and Minecraft forwards are intended to be public.
Other web services are for the home LAN or VPN. A port allowed by Nico's host
firewall is not necessarily forwarded by the router.

Nico's NixOS and Home Manager state versions are both `25.11`.

## Home Manager

Home Manager is embedded into each NixOS configuration and manages the
`reisdro` account.

`modules/home/common.nix` provides the shell, Git, Neovim, SSH client,
directory environment, and shared terminal tools. Clancy imports its graphical
modules and package list from `hosts/clancy/`; Nico adds only its server-side
tools.

The system user remains mutable because its password and SSH credentials are
not yet provisioned declaratively. Account recovery therefore remains part of
the mutable-state runbook.

## Validate and build

Evaluate every host without building or activating anything:

```sh
./scripts/check eval
```

Build one complete system closure without creating a `result` link or
activating it:

```sh
./scripts/check build clancy
./scripts/check build nico
```

The evaluation command uses `path:.`, which includes new untracked files while
developing. A normal Git-backed `.#host` reference only includes files known to
Git.

GitHub Actions runs the same evaluation for pushes and pull requests. CI has
read-only repository access, receives no decryption key, and never builds,
activates, or deploys a host.

Format Nix files with the formatter pinned by the flake:

```sh
nix fmt
```

## Activate a configuration

Activation is deliberately separate from validation. On the target host:

```sh
sudo nixos-rebuild test --flake ~/dots#$(hostname)
sudo nixos-rebuild switch --flake ~/dots#$(hostname)
```

The `rebuild` shell alias runs the `switch` command. Prefer `test` first when a
change affects networking, storage, boot, SSH, or important services.

Before the first Nico activation, confirm from another terminal that public-key
login works without an interactive password prompt:

```sh
ssh -o BatchMode=yes nico true
```

Nico disables password, keyboard-interactive, and root SSH login. Do not close
the existing administrative session until a second key-only session succeeds.

An optional remote invocation is:

```sh
nixos-rebuild switch \
  --flake path:.#nico \
  --target-host reisdro@nico \
  --use-remote-sudo
```

Remote deployment is a convenience, not a requirement. For risky Nico changes,
keep an existing SSH session open and ensure local console access is possible.

No CI workflow deploys either machine.

## Roll back

From a working system:

```sh
sudo nixos-rebuild switch --rollback
```

If the machine does not boot normally, select an older NixOS generation in the
bootloader. Avoid aggressive garbage collection until a migration has been
stable long enough that its previous generations are no longer needed.

Rollback restores declarative configuration. It does not reverse database
migrations, restore `/data`, recover deleted files, or recreate external
secrets. See [the recovery runbook](docs/recovery.md).

## Add a service

For a service that belongs to Nico:

1. Put it in the closest topical file under `hosts/nico/`, or create one
   cohesive new file and add it to `hosts/nico/default.nix`.
2. Choose where its mutable state lives.
3. If it uses `/data`, add explicit mount ordering and requirements.
4. Bind its web listener to localhost where practical and expose it through
   the existing nginx/TLS boundary.
5. Open only required host-firewall ports. Router forwarding is a separate,
   manual decision.
6. Keep credentials outside the Nix store and follow `docs/secrets.md`.
7. Run `./scripts/check eval`, then build Nico before considering activation.

Do not introduce an enable option merely because the service has its own file.
Nico is expected to run its complete server stack.

## Add or replace a host

For a genuinely new host:

1. Copy the closest existing host directory.
2. Replace its generated hardware configuration and installation-specific
   facts.
3. Set conservative NixOS and Home Manager state versions for the fresh
   installation.
4. Add one explicit `nixosConfigurations.<name>` entry to `flake.nix`.
5. Add the host name to `scripts/check`.
6. Add it to the host table near the top of this README.
7. If it consumes encrypted secrets, add its public recipient and intended
   path policy to `.sops.yaml` before re-keying any ciphertext.
8. Evaluate and build it before installation or activation.

The planned hardware rotation is intentionally explicit: the future Framework
becomes Clancy, the current Asus becomes Nico, and the current MSI becomes
Backup. At that time, change the three host directories deliberately and
validate them independently. Clancy's desktop behavior must be separated from
its current Asus graphics/VFIO/home-hardware files; Nico's services must be
combined with the Asus and future DAS facts; and the MSI must receive a new
Backup configuration. The repository is optimized for ordinary maintenance
rather than making that rare rotation automatic.

Disko should be introduced with the future Framework or another fresh
installation, not retrofitted onto the current filesystems during this
refactor.

## Secrets and mutable state

The repository currently references machine-local plaintext files under
`/etc/secrets`, `/etc/wireguard`, and `/var/lib`. They are not copied into Nix
store derivations, but they are also not yet reproducibly provisioned.

The agreed replacement is sops-nix. Encrypted files use both current machines
as recipients, so either Clancy or Nico can recover and re-key them. There is
no separate offline recovery key. The migration needs local access to the
existing files; real secret values must never be pasted into chat or committed
unencrypted. See [the secrets runbook](docs/secrets.md).

Nix can recreate configuration, but not databases, Minecraft worlds, Immich
media, VM disks, SSH host keys, NetworkManager profiles, passwords, or personal
files. Automated backups are not configured yet. See
[the recovery runbook](docs/recovery.md) before treating a host as recoverable.

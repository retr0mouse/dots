# Recovery and rollback runbook

## Current recovery status

The NixOS configuration can recreate system policy and installed software, but
automated data backups are not configured. A host is therefore not yet fully
recoverable from this repository alone.

The first backup priorities are:

1. Immich originals and database state.
2. Minecraft worlds and server state.
3. Future document storage.
4. Movies, shows, and music after backup capacity is available.

The final destination, retention policy, and treatment of large media remain
open until the planned DAS and backup capacity are known.

## Mutable-state inventory

Important state outside the Nix configuration includes:

- `/data`, including Immich and media libraries
- `/var/lib/immich` and the Immich PostgreSQL data at
  `/var/lib/postgresql/immich`
- `/var/lib/minecraft`
- Vaultwarden data and environment
- Grafana, Prometheus, Uptime Kuma, and other application databases
- libvirt domain XML, the `windows11` disk, and libvirt networks
- `/etc/secrets` and `/etc/wireguard`
- SSH host keys, user authorized keys, and mutable passwords
- NetworkManager connection profiles
- user files and mutable application configuration, including Waypaper and
  monitor profiles

Before introducing a backup job, confirm every application's consistency
requirements. Copying a live database file is not automatically a valid
database backup.

## Configuration rollback

Keep previous generations until the new configuration has been stable.

From a running host:

```sh
sudo nixos-rebuild switch --rollback
```

If normal boot fails, choose an older generation from the bootloader. A
rollback changes declarative system configuration; it does not undo data or
database migrations performed by an application.

For a risky Nico activation:

1. Build first without activation.
2. Keep an existing SSH session open.
3. Confirm local-console access.
4. Use `nixos-rebuild test` before `switch`.
5. Check SSH, the LAN address, WireGuard, `/data`, nginx, DNS, and affected
   services before closing the old session.
6. Do not garbage-collect the old generation immediately.

## Reconstructing a current host

The current machines do not use Disko, so disk creation and mounting remain a
manual installation step.

High-level recovery order:

1. Boot a NixOS installer and recreate the intended partition/filesystem
   layout.
2. Mount the filesystems and ensure their UUIDs match the checked-in host
   configuration, or deliberately update the configuration.
3. Clone this repository.
4. Restore the target's SSH host key from an encrypted backup, or use the
   surviving machine to decrypt and re-key the SOPS files for a new host key.
5. Install the matching configuration so its users and groups exist, while
   keeping stateful applications stopped until their data is restored.
6. Restore bulk data, databases, and remaining mutable state with the expected
   ownership and permissions.
7. Boot or activate the recovered system.
8. Restore the administrator's authorized key or password before relying on
   remote access.
9. Verify mounts, key-only SSH, network access, application databases, and
   backups before considering recovery complete.

The future Framework installation should introduce a reviewed Disko layout.
That will make filesystem provisioning reproducible for new installations but
will not itself back up any data.

## Failure isolation

- A Clancy evaluation or build failure does not require changing Nico.
- A Nico service change should be built and activated without touching
  Clancy.
- Keep structural refactors separate from service-policy or data migrations.
- If `/data` is unavailable, do not start storage-backed applications merely
  to make their units appear green; fix or recover the mount first.
- If remote access is lost, use the local console and select the previous boot
  generation rather than making blind additional network changes.

## Backup completion criteria

A future backup design is complete only when:

- every priority dataset has an explicit source and destination;
- retention and expected storage growth are documented;
- SSH host keys are included in encrypted backups that do not exist only on
  the host they unlock, or another surviving recipient is documented;
- application-consistent backup procedures are defined;
- failed jobs are visible;
- at least one restore test has succeeded on separate storage;
- the recovery procedure does not depend on the failed Nico installation.

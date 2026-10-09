# Secrets runbook

## Current state

Secret values are currently maintained as mutable files on each machine. Nix
refers to their paths but does not create them.

| Host | Current path | Consumer |
| --- | --- | --- |
| Clancy | `/etc/wireguard/privatekey` | WireGuard client |
| Clancy | `/etc/secrets/wireguard-home-network.env` | automatic home/away VPN policy |
| Nico | `/etc/wireguard/privatekey` | WireGuard server |
| Nico | `/etc/secrets/duckdns-acme-env` | ACME DNS challenge |
| Nico | `/etc/secrets/duckdns-token` | DuckDNS updater |
| Nico | `/etc/secrets/grafana-secret-key` | Grafana signing/encryption key |
| Nico | `/etc/secrets/minecraft.env` | Minecraft RCON password substitution |
| Nico | `/etc/secrets/slskd.env` | slskd environment |
| Nico | `/var/lib/vaultwarden/vaultwarden.env` | Vaultwarden environment |

This avoids copying values into the Nix store, but provisioning and disaster
recovery remain manual.

## Intended sops-nix design

Each encrypted file under `secrets/clancy/` or `secrets/nico/` has both current
machines as recipients. Either machine can therefore decrypt and re-key every
configuration secret. There is no separate personal or offline recovery key.

Both current machines already have an SSH Ed25519 host key. Clancy does not
enable an SSH server declaratively, but its existing host key can still be
used locally by sops-nix; enabling SSH merely to obtain an age recipient is
unnecessary.

| Host | Public age recipient |
| --- | --- |
| Clancy | `age19dp60wvpk8uynvsja4x853k3uhvcwntuuv26wmz8r302awk4cc3quw7zc7` |
| Nico | `age1ryaw5fk24t9gpjs7qmhp4m32hanl6cah95l0fx7gv3cq6lvs2ucs56em4l` |

These values are public and were derived from each machine's
`/etc/ssh/ssh_host_ed25519_key.pub`. The matching private host keys remain on
their machines. Replacing or regenerating a host key requires adding the new
recipient and re-encrypting that host's secrets before removing the old one.

This policy trades isolation for straightforward recovery: compromising either
host key exposes all encrypted configuration secrets. Conversely, losing both
private host keys makes the committed ciphertext unrecoverable. Normal
encrypted backups must eventually include the host keys, or a future third
machine must be added as another recipient.

Neither current root filesystem has declarative disk encryption. Physical
access to either disk can therefore expose that machine's SSH host key and,
under the mutual-recipient policy, every configuration secret. This is the
main security cost of avoiding a separate recovery identity.

The checked-in `.sops.yaml` contains only public recipients. Encrypted files
contain ciphertext and may be committed. Private keys, decrypted values, and
plaintext scratch files must never be committed.

## Repository file safety

Encrypted files must live below `secrets/clancy/` or `secrets/nico/` and use a
name ending in `.sops` or `.sops.<format>`. `.gitignore` rejects other names
under `secrets/` as a last line of defense.

Never create a plaintext file anywhere inside this repository, even if Git
ignores it. Local checks use the `path:.` flake URL, which can copy untracked
working-tree content into the Nix store.

The pinned command-line tools can be opened without installing them globally:

```sh
nix shell --inputs-from . nixpkgs#sops nixpkgs#ssh-to-age
```

Confirm a machine recipient from its public key with:

```sh
ssh-to-age < /etc/ssh/ssh_host_ed25519_key.pub
```

When encrypting a file from outside the repository, pass a repository-relative
`--filename-override` such as `secrets/nico/example.env.sops`. Otherwise SOPS
matches the creation rules against the plaintext source path instead of the
encrypted destination. Always specify the input/output format when the `.sops`
suffix does not identify it. Root-owned source files require an explicitly
reviewed elevated command; do not weaken their permissions or copy them into
the repository for convenience.

## Bootstrap requirements

The creation policy and both public recipients are now present. Before
migrating any consumer:

- Verify the matching private host key remains present on both machines.
- Test an encrypted non-production sample from both machines.
- Confirm the sample metadata contains both intended public recipients.
- Keep local access to every existing plaintext file; do not paste values into
  chat or command logs.

Only public host keys leave their target machines during policy setup.

## Migration sequence

Migrate one host and one consumer at a time:

1. The sops-nix flake input and NixOS module are already present, but no
   consumer has been changed yet.
2. Confirm `.sops.yaml` still contains both current public recipients.
3. Encrypt the existing file locally as an opaque binary secret. This
   preserves unknown environment-file formatting during the first migration.
4. Declare the secret with explicit mode, owner, and group.
5. Point exactly one consumer at `config.sops.secrets.<name>.path`.
6. Evaluate and build the host.
7. With separate activation approval, test the generation and verify the
   affected service.
8. Retain the old plaintext path through the rollback window.
9. Remove the old file only after decryption from the other host and rollback
   have both been tested.

Recommended order:

1. Clancy's home-network environment file.
2. Clancy's WireGuard key while local network access remains available.
3. Nico's application-level secrets individually.
4. Nico's ACME and DuckDNS credentials.
5. Nico's WireGuard key last, from LAN or local-console access rather than
   through the VPN being changed.

Before assigning ownership, inspect the evaluated systemd unit. Grafana needs
to read its own key, while root-owned mode `0400` is normally appropriate for
WireGuard keys and systemd-loaded environment files.

## CI policy

GitHub Actions may evaluate configurations that reference encrypted sops files.
It must never receive a production private key, decrypted output, deployment
credential, or machine SSH key. CI is validation, not deployment.

## Rotation and machine replacement

To replace hardware:

1. Add the replacement machine's public recipient to the relevant creation
   rule.
2. Re-encrypt all files for the two retained recipients plus the replacement.
3. Verify decryption on the replacement and one existing host without printing
   values.
4. Complete the host transfer.
5. Remove the retired machine's recipient and rotate secrets whose old copies
   cannot be trusted.

Removing ciphertext or a recipient does not erase values from Git history,
old clones, old system generations, or backups. Rotate any secret that has
ever been exposed in plaintext.

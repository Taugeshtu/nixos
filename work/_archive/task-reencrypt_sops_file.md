# Task: Re-encrypt SOPS File

- **Project**: [[nixOS_move]]
- **Date**: 2026-08-30
- **Status**: Open

## Context
Need to re-encrypt the SOPS file (`secrets.yaml` / master age key) because the password in head was not the one on the file.

## Track of the epics

- [x] Settle on a new architecture for the fleet inter-connectivity
    Picked out design: every machine gets its own public-private keys; github is trained on these keys. Blorbital gets them, so does Orbital. Orbital, when migrating to nix, will get them as part of the nix config.
- [x] Generate 3 new keys
- [x] Write new docs for install/recovery procedure
- [x] Generate new master key (`keys.txt`) and encrypt it into `keys.age` using new head password
- [x] Update `.sops.yaml` with new Age public key
- [x] Encrypt secrets into sops-nix (`secrets.yaml`) using new master key
- [x] Update `secrets.nix` (per-host secret paths)
- [x] Update `authorizedKeys` across host configs (Tower, Codex, Slate) with new public keys
- [x] Validate new secrets work (rebuild + switch NixOS, test GitHub auth, SSH across Tailscale mesh, SSH into both VPS)
- [x] Post-validation cleanup:
    - [x] Remove old `grug_vps` key from Blorbital (`authorized_keys`)
    - [x] Remove old shared key from GitHub (manual in web settings)
    - [x] Remove `~/new_fleet_keys/` staging folder
    - [x] Delete obsolete `bootstrap.sh` and `bootstrap.md` from repo root

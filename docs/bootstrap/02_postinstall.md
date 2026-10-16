# Stage 02: Post-Install State & Fleet Sync

This document covers non-declarative user state, data sync, and application profiles after the system and tools are operational.

---

## 1. Fleet Sync & Domain Restoration

Follow the storage topology in [fleet_sync.md](../fleet_sync.md) to link this node to the Tower master anchor:

1. **Mutagen Configuration**:
   Verify global Mutagen configuration exists at `~/.mutagen.yml`.
2. **Start Domain Sync**:
   Start initial Mutagen sync sessions for active domains (`00_INGRESS`, `05_WORK`, `K`, `T`):
   ```bash
   mutagui
   ```
   *(Or activate individual projects using `prj activate <PROJECT>`)*.
3. **Verify Rclone VFS Cold Mounts**:
   Ensure systemd user mount units for `_archive` and media domains are active:
   ```bash
   systemctl --user status "rclone-*"
   ```

---

## 2. Browser & Application Profiles

- **Waterfox / Firefox Profiles**:
  Restore or log into profile sync to populate extensions, containers, and bookmarks.
- **Terminal & Shell State**:
  Verify your shell aliases, micro editor themes, and prompt render correctly.

---

## 3. Host-Specific Post-Install Checks

### On Codex
- Verify power profile management:
  ```bash
  powerprofilesctl
  ```
- Verify Sunshine / Moonlight streaming client connection to Tower.

### On Tower
- Verify secondary encrypted NVMe array and bulk storage:
  ```bash
  unlock-vault
  lsblk
  ```
- Check model-serving and virtual displays:
  ```bash
  systemctl status model-serving
  ```

### On Slate
- Check TouchEdgeGlide / keyd input daemon:
  ```bash
  systemctl status keyd
  ```

---

## 4. Disaster Recovery Validation

Verify that your system is fully independent:
1. `git pull` from GitHub works without password prompts (using `id_ed25519_<host>`).
2. `ssh tower` (or `ssh codex`) works across the Tailscale mesh.
3. `sops` can view or edit secrets:
   ```bash
   sops ~/10_PROJECTS/nixOS/nixOS_config/secrets/secrets.yaml
   ```

The machine is now fully provisioned and part of the fleet.

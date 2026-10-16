# Stage 00: Installation from Live Media

This document covers installing NixOS onto bare-metal hardware using the NixOS Minimal or Graphical installer USB.

---

## 1. Prerequisites

- A bootable USB with the official NixOS installer (minimal or graphical).
- The target machine connected to the internet (Ethernet or `nmtui` for Wi-Fi).

---

## 2. Boot & Clone Configuration

Once booted into the live installer environment:

1. Obtain a root shell (or run commands with `sudo`).
2. Clone this repository into the live environment's RAM:
   ```bash
   git clone https://github.com/Taugeshtu/nixOS.git /tmp/nixos-config
   cd /tmp/nixos-config/nixOS_config
   ```

---

## 3. Storage Partitioning

Select your target machine:

### Option A: Machines with Disko (Slate, Orbital)
For machines defined with Disko modules:
```bash
# Preview actions
sudo nix run github:nix-community/disko -- --mode mount ./hosts/<machine>/disko.nix

# Execute partitioning and formatting
sudo nix run github:nix-community/disko -- --mode disko ./hosts/<machine>/disko.nix
```

### Option B: Manual Vault/System Layout (Codex, Tower)
For machines following the two-stage layout defined in [storage_map.md](../storage_map.md):
1. Partition NVMe into `/boot` (ESP), `vault` (LUKS2), and `system` (unencrypted Btrfs tail).
2. Open LUKS container:
   ```bash
   cryptsetup open /dev/disk/by-partlabel/vault cryptroot
   ```
3. Mount target filesystems under `/mnt` (`/mnt/boot`, `/mnt/nix`, `/mnt/home/tau`).

---

## 4. Install the System

Run the installer pointing directly to your machine configuration:

```bash
sudo nixos-install --flake .#<host>
```

*(Replace `<host>` with `codex`, `tower`, or `slate`).*

When prompted, set an initial password for user `tau`.

> [!IMPORTANT]
> **Codex & Tower Password Matching Rule**:
> On Codex and Tower, the password set for user `tau` **must exactly match** the LUKS passphrase used to format the `vault` container. The PAM login hook (`unlock.nix`) passes your login password directly to `cryptsetup` to unlock and mount `/home/tau`. If they do not match, the Vault will fail to unlock at login.

---

## 5. First Reboot

1. Unmount and close encrypted partitions:
   ```bash
   umount -R /mnt
   cryptsetup close cryptroot 2>/dev/null || true
   ```
2. Reboot into the installed system:
   ```bash
   reboot
   ```
3. Proceed to [01_fullbody.md](./01_fullbody.md).

# Storage & Partition Map

## 1. Primary Disk Partition Layout (Codex & Tower OS NVMe)

Direct primary GPT partitions (no LVM):

```text
1TB NVMe Drive Layout:
├── Partition 1: /boot   (1 GB, FAT32 EFI ESP, unencrypted)
├── Partition 2: vault   (~950 GB, LUKS2 container)
│   └── Btrfs Filesystem
│       ├── @home        → /home/tau
│       ├── @cache       → /cache (Codex only; Tower uses Quad-RAID)
│       └── @swap        → /swap (optional encrypted swapfile)
└── Partition 3: system  (50 GB aligned tail, unencrypted Btrfs)
    ├── @nix             → /nix
    ├── @persist         → /persist (if impermanence enabled)
    ├── @var_log         → /var/log   (nodatacow, no snapshots)
    ├── @var_cache       → /var/cache (no snapshots)
    ├── @var_tmp         → /var/tmp   (no snapshots)
    └── @kiosk_home      → /home/kiosk
```

---

## 2. Locked Memory & Swap Policy

- Unencrypted `system` partition has **zero swap**.
- In locked state (Stage 1), the system operates entirely swapless, utilizing `zram` memory compression.
- Any disk-backed swap resides strictly inside the unlocked encrypted Vault partition.

### Swap on Btrfs Rules
Btrfs is Copy-on-Write (CoW). The kernel swap subsystem requires static physical sector offsets.
- Never use `fallocate` on Btrfs.
- Setup inside Vault:
  ```bash
  truncate -s 0 /swap/swapfile
  chattr +C /swap/swapfile       # Disable CoW on empty file
  dd if=/dev/zero of=/swap/swapfile bs=1M count=32768
  chmod 600 /swap/swapfile
  mkswap /swap/swapfile
  swapon /swap/swapfile
  ```

---

## 3. Tower Auxiliary Storage Array

- **Quad-NVMe RAID (`/cache`)**: 4-NVMe array formatted with LUKS2 → XFS or Btrfs.
- **Bulk Storage (`/data` or `/cold`)**: 3TB HDD formatted with LUKS2 → Btrfs.
- **Unlock Orchestration**:
  1. Tau enters passphrase once to unlock the primary Vault partition.
  2. The unlock routine retrieves keyfiles stored within the Vault.
  3. The secondary Quad-RAID and HDD are decrypted and mounted automatically with zero additional prompts.

---

## 4. Encryption Layer Architecture

- **Layer 0 (System Partition, Tail 50GB)**: Unencrypted Nix store, kiosk environment, base services. No personal secrets.
- **Layer 1 (Vault Partition & Auxiliary Drives)**: LUKS2-encrypted containers protected by passphrase and keyfiles.

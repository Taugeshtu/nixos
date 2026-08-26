# Evil Maid Mitigation Plan (dm-verity + Lanzaboote)

> _Status_: **Deferred**. Do not apply to single active machine. Execute when secondary host or rescue environment is operational.

---

## 1. Threat Model & Goal

- **Vector**: Attacker with physical access boots live media and modifies unencrypted `/boot` or Stage 1 `system` partition (injecting keylogger or modified PAM/sshd).
- **Goal**: Protect LUKS passphrase and Vault contents during local or remote unlock, while preserving unattended Stage 1 boot (Headscale mesh VPN + Kiosk).
- **Hardware Requirement**: UEFI motherboard with custom Secure Boot key enrollment (no physical TPM module required).

---

## 2. Architecture Overview

```text
Motherboard UEFI NVRAM (Custom PK / KEK / db keys)
  │
  ▼ [Verifies signature on boot]
Signed Unified Kernel Image (.efi via Lanzaboote)
  ├── Linux Kernel + Microcode + initrd
  └── Kernel Command Line: roothash=<dm-verity-root-hash>
        │
        ▼ [Crypto layer validates every disk block]
Unencrypted Stage 1 Root (dm-verity verified)
  ├── Nix store & Stage 1 binaries (Read-Only)
  ├── /tmp (tmpfs in RAM)
  └── /var/log (volatile journal in RAM, ~30MB)
        │
        ▼ [Unattended Boot Complete -> Headscale + Kiosk active]
Stage 2 Unlock Routine
  ├── Decrypts Vault (LUKS2)
  ├── Mounts /home/tau (@home)
  ├── swapon /swap/swapfile (Enables disk-backed encrypted swap)
  └── journalctl --flush (Flushes logs to encrypted disk)
```

---

## 3. Storage & Memory Policy

### Stage 1 (Locked State)
- **Swap**: Zero disk swap. Operates swapless with `zram` memory compression.
- **`/tmp`**: Backed strictly by `tmpfs` (`boot.tmp.useTmpfs = true;`).
- **`/var/log`**: In-memory volatile journal (`services.journald.extraConfig = "Storage=volatile";`). Memory footprint is under 50MB.
- **Total Stage 1 RAM footprint**: ~300MB–400MB total.

### Stage 2 (Unlocked State)
- Unlock script decrypts `/dev/disk/by-partlabel/vault`.
- Mounts encrypted filesystems.
- Activates pre-allocated CoW-disabled swapfile inside Vault (`/swap/swapfile`).
- Heavy compute and memory allocations now have full disk swap backing.

---

## 4. Implementation Steps (Future Work)

### Step 1: Secure Boot Custom Key Generation
1. Generate tau private PK (Platform Key), KEK (Key Exchange Key), and db keys.
2. Put UEFI firmware into "Setup Mode".
3. Enroll tau custom keys into motherboard NVRAM using `sbctl` or UEFI BIOS menu.

### Step 2: Lanzaboote Setup in Flake
1. Add `lanzaboote` input to `flake.nix`.
2. Configure Lanzaboote module in host configuration:
   - Point to private signing keys.
   - Replace standard `systemd-boot` with Lanzaboote signed UKI generation.
3. Verify test boot into signed UKI.

### Step 3: dm-verity Integration
1. Build Stage 1 root filesystem image with `veritysetup` / `systemd-repart`.
2. Pass generated root hash into Lanzaboote UKI kernel parameters.
3. Configure `initramfs` to mount root with verity validation.
4. Automate rebuild workflow so `nixos-rebuild switch` recalculates verity hash and signs updated `.efi`.

### Step 4: Verification & Failure Testing
1. Boot normal signed kernel -> verify clean boot.
2. Attempt booting modified file on Stage 1 partition from live USB -> verify kernel panic / halt on block read.
3. Attempt modifying kernel parameters -> verify UEFI refuses execution.

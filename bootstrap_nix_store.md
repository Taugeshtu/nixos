# Issue: Kernel Build Disk Exhaustion on Codex & Storage Tiering

## Context & Hardware Setup
- **Machine**: Codex (Lenovo IdeaPad 5 Pro 16ACH6).
- **Task**: Building `nixosConfigurations.slate` system closure (specifically the `linux-surface` kernel `linux-6.19.8`) to deploy onto Slate (Surface Go 3) via `nixos-anywhere`.
- **Disk Topology on Codex**:
  - `/dev/nvme0n1p3` (50GB unencrypted Btrfs `NIXSYSTEM`): hosts `/`, `/nix`, `/var/log`, `/var/cache`, `/home/kiosk`.
  - `/dev/mapper/nvme_vault` (~950GB LUKS2 encrypted Btrfs `VAULT`): hosts `/home/tau` and `/cache` (currently has **408GB free space**).

---

## The Problem
When building the `linux-surface` kernel derivation (`/nix/store/...-linux-6.19.8.drv`), the build repeatedly fails with:

```text
fatal error: error writing to /build/cc...s: No space left on device
make: *** [Makefile:248: __sub-make] Error 2
note: build failure may have been caused by lack of free disk space
```

### Root Causes

1. **`/tmp` / Build Directory Exhaustion**:
   - Compiling the Linux kernel generates ~15–20GB of intermediate `.o` object files in the sandbox `/build` directory.
   - The build is executed by `nix-daemon`, which by default allocates its temporary sandbox build directories in `/tmp`.
   - `/tmp` lives on `/dev/nvme0n1p3` (the 50GB unencrypted partition), where `/nix/store` already consumes ~44GB. This leaves only ~1.5GB–2.8GB of free space on `/`, causing GCC to hit `No space left on device`.

2. **`/tmp` Mount Isolation via PAM / Greetd**:
   - An attempt was made in `hosts/codex/unlock.nix` to run `mount --bind /cache/tmp /tmp` when user `tau` logs in.
   - However, PAM execution under `greetd` runs inside an isolated systemd mount namespace. The bind mount did not propagate to PID 1 or to the pre-existing background `nix-daemon` system service, leaving the system-wide `/tmp` and `nix-daemon` still attached to the nearly-full 50GB partition.

3. **Build Artifacts & Transients in `/nix/store`**:
   - In addition to sandbox compilation churn in `/tmp`, building a custom kernel downloads build tools, source tarballs (`linux-6.19.8.tar.xz`), headers, and compilers into `/nix/store`.
   - On the 50GB partition, having both long-term system generations and transient build dependencies easily exhausts the remaining disk headroom.

---

## Objectives & Requirements

1. **Relocate Build Scratch Space to LUKS Vault**:
   - Ensure that `nix-daemon` (and user compilation tasks) perform heavy, high-churn compilation operations inside `/cache/tmp` (on the 408GB encrypted `VAULT`), completely bypassing the small 50GB unencrypted `/tmp`.

2. **Fix System-Wide `/tmp` Post-Unlock**:
   - Once the LUKS Vault is unlocked upon user `tau` login, `/tmp` should be properly bound/mounted to the encrypted `/cache/tmp` across the entire system (including PID 1 and all background daemons).

3. **Separate Active Generations from Build-Time Churn**:
   - Keep the unencrypted 50GB partition lean (holding only the ~26GB runtime closures for active system generations).
   - Route high-churn, discardable build artifacts and dependencies to `/cache` or enforce automatic store pruning (`min-free` / `max-free` thresholds in Nix settings).

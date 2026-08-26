# Cache Delegation Map

## 1. Criteria

### Delegated to `/cache` (`@cache` subvolume / Quad-RAID)
- **High Churn / Build Artifacts**: Compilers, package managers, and toolchains that write frequent temporary files or download dependencies.
- **Single-Point Reproducibility**: Game runtimes, engine binaries, and prefixes that can be re-downloaded or re-generated with one click or command.
- **Snapshot Exclusion**: Anything that would bloat Btrfs snapshots of `@home` or slow down backups.
- **Zero Loss Grief**: Data that can vanish overnight without loss of creative work, configurations, or personal history.

### Retained in `@home` (Persistent / Snapshotted / Backed Up)
- **Scattered Source Binaries**: `~/Applications` (AppImages, custom tarballs, manual installs from diverse sources).
- **Agent Intelligence**: `~/.gemini` (conversation histories, transcripts, and brain states).
- **Inboxes & Captures**: `~/15_Downloads`, `~/20_ScreenGrabs`, loose files in `~`.
- **Knowledge & Work**: `~/00_INGRESS`, `~/05_WORK`, `~/K`, `~/10_PROJECTS`.

---

## 2. Active Delegation Map

| Item / Category | Original Path (`@home`) | Delegated Target (`/cache`) | Notes |
|---|---|---|---|
| **XDG Cache** | `~/.cache` | `/cache/dotcache` | Standard application and browser caches |
| **Rust Toolchains** | `~/.rustup` | `/cache/rustup` | Rust toolchains installed via rustup |
| **Pico SDK** | `~/.pico-sdk` | `/cache/pico-sdk` | Raspberry Pi Pico SDK & toolchains |
| **Cargo Cache** | `~/.cargo` | `/cache/cargo` | Cargo registry, git checkouts, and build cache |
| **NuGet Packages** | `~/.nuget` | `/cache/nuget` | .NET / NuGet package cache |
| **.NET Tools/SDK** | `~/.dotnet` | `/cache/dotnet` | .NET runtime files and telemetry |
| **Node Versions** | `~/.nvm` | `/cache/nvm` | NVM Node version manager installs |
| **NVIDIA Shaders** | `~/.nv` | `/cache/nv` | GL and Compute shader caches |
| **NPM Cache** | `~/.npm` | `/cache/npm` | Global npm cache |
| **Go Modules** | `~/go/pkg` | `/cache/go/pkg` | Go downloaded module cache (`GOMODCACHE`) |
| **Steam** | `~/.local/share/Steam` | `/cache/Steam` | Steam client, downloads, runtime |
| **Bottles** | `~/.var/app/com.usebottles.bottles` | `/cache/bottles` | Flatpak Bottles Wine prefixes |
| **Proton Prefixes** | `~/proton-compatdata` | `/cache/proton-compatdata` | Steam Proton compatdata directories |
| **PrismLauncher** | `~/.var/app/org.prismlauncher.PrismLauncher` | `/cache/prismlauncher` | Minecraft instances & assets |
| **Unity Hub** | `~/Unity/Hub` | `/cache/UnityHub` | Unity Editor engine binaries |

---

## 3. NixOS Integration Target

- **Btrfs Mount**:
  ```nix
  fileSystems."/cache" = {
    device = "/dev/mapper/nvme_vault";
    fsType = "btrfs";
    options = [ "subvol=@cache" "compress=zstd" "noatime" ];
  };
  ```
- **Environment Exports (Session / Home Manager)**:
  ```bash
  export XDG_CACHE_HOME="/cache/dotcache"
  export CARGO_HOME="/cache/cargo"
  export RUSTUP_HOME="/cache/rustup"
  export NUGET_PACKAGES="/cache/nuget"
  export NVM_DIR="/cache/nvm"
  export NPM_CONFIG_CACHE="/cache/npm"
  export DOTNET_CLI_HOME="/cache/dotnet"
  export CUDA_CACHE_PATH="/cache/nv"
  export GOMODCACHE="/cache/go/pkg/mod"
  ```
- **Tmpfiles / Symlinks**:
  Use `systemd.user.tmpfiles.rules` or `home.file` symlinks to wire legacy hardcoded paths to `/cache`.

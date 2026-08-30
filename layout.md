# NixOS Configuration Surface & Layout

- [[Domain_NixOS]]
- [[Codex]]
- [[Slate]]
- [[Tower]]

Modular configuration tree layout and surface.

---

### 1. [flake.nix](file:///home/tau/10_PROJECTS/nixOS_move/nixOS_config/flake.nix)

- **Inputs**:
  - `nixpkgs.url`: string (`"github:NixOS/nixpkgs/nixos-unstable"`)
  - `home-manager.url`: string (`"github:nix-community/home-manager"`)
  - `imv-dir-respect.url`: string (`"github:Taugeshtu/imv-dir-respect"`, `flake = false`)
  - `to-day.url`: string (`"github:Taugeshtu/TO-DAY"`, `flake = false`)
  - `bt-ghost-note.url`: string (`"github:Taugeshtu/bt_ghost_note"`, `flake = false`)
  - `sops-nix.url`: string (`"github:Mic92/sops-nix"`)
  - `nixos-hardware.url`: string (`"github:NixOS/nixos-hardware/master"`)
  - `disko.url`: string (`"github:nix-community/disko"`)
- **Exports**:
  - `nixosConfigurations.codex`: IdeaPad 5 Pro 16ACH6 configuration
  - `nixosConfigurations.slate`: Surface Go 3 configuration
  - `nixosConfigurations.tower`: AMD EPYC / Radeon VII Workstation configuration

---

### 2. Host Configurations (`hosts/`)

#### [hosts/codex/default.nix](file:///home/tau/10_PROJECTS/nixOS_move/nixOS_config/hosts/codex/default.nix)
- **Imports**:
  - [`./hardware.nix`](file:///home/tau/10_PROJECTS/nixOS_move/nixOS_config/hosts/codex/hardware.nix)
  - [`./unlock.nix`](file:///home/tau/10_PROJECTS/nixOS_move/nixOS_config/hosts/codex/unlock.nix)
  - [`../../modules/core/base.nix`](file:///home/tau/10_PROJECTS/nixOS_move/nixOS_config/modules/core/base.nix)
  - [`../../modules/core/users.nix`](file:///home/tau/10_PROJECTS/nixOS_move/nixOS_config/modules/core/users.nix)
  - [`../../modules/keyd.nix`](file:///home/tau/10_PROJECTS/nixOS_move/nixOS_config/modules/keyd.nix)
  - [`../../modules/desktop/base.nix`](file:///home/tau/10_PROJECTS/nixOS_move/nixOS_config/modules/desktop/base.nix)
  - [`../../modules/desktop/theme.nix`](file:///home/tau/10_PROJECTS/nixOS_move/nixOS_config/modules/desktop/theme.nix)
  - [`../../modules/desktop/future.nix`](file:///home/tau/10_PROJECTS/nixOS_move/nixOS_config/modules/desktop/future.nix)
  - [`../../modules/desktop/lock.nix`](file:///home/tau/10_PROJECTS/nixOS_move/nixOS_config/modules/desktop/lock.nix)
  - [`../../modules/desktop/workstation.nix`](file:///home/tau/10_PROJECTS/nixOS_move/nixOS_config/modules/desktop/workstation.nix)
  - [`../../modules/desktop/gaming.nix`](file:///home/tau/10_PROJECTS/nixOS_move/nixOS_config/modules/desktop/gaming.nix)
  - [`../../modules/flatpaks/base.nix`](file:///home/tau/10_PROJECTS/nixOS_move/nixOS_config/modules/flatpaks/base.nix)
  - [`../../modules/flatpaks/everyday.nix`](file:///home/tau/10_PROJECTS/nixOS_move/nixOS_config/modules/flatpaks/everyday.nix)
  - [`../../modules/flatpaks/communications.nix`](file:///home/tau/10_PROJECTS/nixOS_move/nixOS_config/modules/flatpaks/communications.nix)
  - [`../../modules/flatpaks/workstation.nix`](file:///home/tau/10_PROJECTS/nixOS_move/nixOS_config/modules/flatpaks/workstation.nix)
  - [`../../modules/flatpaks/waterfox.nix`](file:///home/tau/10_PROJECTS/nixOS_move/nixOS_config/modules/flatpaks/waterfox.nix)
- **Options Set**:
  - `boot.kernelPackages`: `pkgs.linuxPackages_zen`
  - `boot.blacklistedKernelModules`: `[ "pcspkr" ]`
  - `zramSwap`: 8GB zstd swap
  - `networking.hostName`: `"codex"`
  - `boot.loader`: systemd-boot (limit 3, EFI)
  - Audio, Bluetooth, Polkit, Home-manager imports

#### [hosts/slate/default.nix](file:///home/tau/10_PROJECTS/nixOS_move/nixOS_config/hosts/slate/default.nix)
- **Imports**:
  - [`./disko.nix`](file:///home/tau/10_PROJECTS/nixOS_move/nixOS_config/hosts/slate/disko.nix)
  - [`./hardware.nix`](file:///home/tau/10_PROJECTS/nixOS_move/nixOS_config/hosts/slate/hardware.nix)
  - [`../../modules/core/base.nix`](file:///home/tau/10_PROJECTS/nixOS_move/nixOS_config/modules/core/base.nix)
  - [`../../modules/core/users.nix`](file:///home/tau/10_PROJECTS/nixOS_move/nixOS_config/modules/core/users.nix)
  - [`../../modules/keyd.nix`](file:///home/tau/10_PROJECTS/nixOS_move/nixOS_config/modules/keyd.nix)
  - [`../../modules/desktop/base.nix`](file:///home/tau/10_PROJECTS/nixOS_move/nixOS_config/modules/desktop/base.nix)
  - [`../../modules/desktop/theme.nix`](file:///home/tau/10_PROJECTS/nixOS_move/nixOS_config/modules/desktop/theme.nix)
  - [`../../modules/flatpaks/base.nix`](file:///home/tau/10_PROJECTS/nixOS_move/nixOS_config/modules/flatpaks/base.nix)
  - [`../../modules/flatpaks/everyday.nix`](file:///home/tau/10_PROJECTS/nixOS_move/nixOS_config/modules/flatpaks/everyday.nix)
  - [`../../modules/flatpaks/communications.nix`](file:///home/tau/10_PROJECTS/nixOS_move/nixOS_config/modules/flatpaks/communications.nix)
  - [`../../modules/flatpaks/waterfox.nix`](file:///home/tau/10_PROJECTS/nixOS_move/nixOS_config/modules/flatpaks/waterfox.nix)
- **Options Set**:
  - `boot.kernelPackages`: `microsoft-surface-go` (`linux-surface`)
  - `hardware.sensor.iio.enable`: `true` (`iio-sensor-proxy` + `rot8`)
  - `services.thermald.enable`: `true`
  - `zramSwap`: 3GB zstd swap
  - `swapDevices`: 20GB `/cache/swapfile`
  - `networking.hostName`: `"slate"`
  - `environment.systemPackages`: `wvkbd`, `libcamera`, `rot8`

#### [hosts/tower/default.nix](file:///home/tau/10_PROJECTS/nixOS_move/nixOS_config/hosts/tower/default.nix)
- **Imports**:
  - [`./hardware.nix`](file:///home/tau/10_PROJECTS/nixOS_move/nixOS_config/hosts/tower/hardware.nix)
  - [`./unlock.nix`](file:///home/tau/10_PROJECTS/nixOS_move/nixOS_config/hosts/tower/unlock.nix)
  - Core & Desktop modules
- **Options Set**:
  - `boot.kernelParams`: `[ "fbcon=rotate:3" ]` (counter-clockwise screen rotation in initrd/fbcon)
  - `boot.kernelPackages`: `pkgs.linuxPackages_zen`
  - `boot.initrd.kernelModules`: `[ "amdgpu" ]`
  - `hardware.graphics.enable`: `true` (Radeon VII)
  - `networking.hostName`: `"tower"`
  - `boot.loader`: systemd-boot

---

### 3. Core Modules (`modules/core/`)

#### [modules/core/base.nix](file:///home/tau/10_PROJECTS/nixOS_move/nixOS_config/modules/core/base.nix)
- Base CLI tools (micro, git, htop, bat, ripgrep, fd, python3 w/ pillow & numpy, etc.)
- Nix settings & GC
- Locales, time zone, console colors
- Systemd-resolved DNS
- Earlyoom

#### [modules/core/users.nix](file:///home/tau/10_PROJECTS/nixOS_move/nixOS_config/modules/core/users.nix)
- Defines normal user `tau` and `kiosk` user

---

### 4. Desktop Modules (`modules/desktop/`)

#### [modules/desktop/base.nix](file:///home/tau/10_PROJECTS/nixOS_move/nixOS_config/modules/desktop/base.nix)
- Niri WM, Greetd / Tuigreet, Xwayland-satellite, dconf
- Foot, Waybar, MPV, Imv, Macchina, Alacritty, Htop, Swaybg, SwayOSD, SwayNC, Wl-clip-persist, Wlsunset, LXQt PolicyKit
- `bt_ghost_note` package build + `sox`
- Thunar, Tumbler, Ffmpeg, `uca_base.xml` (Terminal Here, Zip-Zero, Video Shrink), `mimeapps.list`
- Core scripts: `niri-launcher`, `smart-terminal`, `niri-navigate`, `niri-zen`, `foot-on-path`, `video_shrink`, `lite-open`, `imv-dir-respect`
- Desktop entries: `lite-open`, `imv-dir`

#### [modules/desktop/theme.nix](file:///home/tau/10_PROJECTS/nixOS_move/nixOS_config/modules/desktop/theme.nix)
- Fontconfig rendering configuration (`fonts.conf`)
- Pure `pointerCursor` with `RedOmen` cursor theme (size 24)

#### [modules/desktop/lock.nix](file:///home/tau/10_PROJECTS/nixOS_move/nixOS_config/modules/desktop/lock.nix)
- PAM service for `gtklock`
- `gtklock`, `swayidle` packages and configs
- `img-coercer`, `chastity`, `chastity-img`, `try-chastity-img` scripts
- `lock.kdl` Niri inclusion

#### [modules/desktop/future.nix](file:///home/tau/10_PROJECTS/nixOS_move/nixOS_config/modules/desktop/future.nix)
- `to-day` derivation package + `smart-today`
- `purse` configs, `purse-defs-smart`, `purse-refs-smart`, `into-purse.sh`, `purse-niri` desktop entry
- `lite-xl` recursive dotfiles
- `touch-edge-glide`, `lsp-broker`, `current` user services and scripts
- `rust-analyzer`, `markdown-oxide` LSP packages
- `libinput-gestures`, `ydotool`, `wtype`, `xdotool`, GTK4 development libraries
- Full `uca_full.xml` custom actions
- `future.kdl` Niri inclusion

#### [modules/desktop/workstation.nix](file:///home/tau/10_PROJECTS/nixOS_move/nixOS_config/modules/desktop/workstation.nix)
- FreeCAD, Blender, Audacity, UnityHub

#### [modules/desktop/gaming.nix](file:///home/tau/10_PROJECTS/nixOS_move/nixOS_config/modules/desktop/gaming.nix)
- PrismLauncher

---

### 5. Flatpak Modules (`modules/flatpaks/`)

- **[base.nix](file:///home/tau/10_PROJECTS/nixOS_move/nixOS_config/modules/flatpaks/base.nix)**: Declarative Flatpaks service + Flatseal, Warehouse
- **[everyday.nix](file:///home/tau/10_PROJECTS/nixOS_move/nixOS_config/modules/flatpaks/everyday.nix)**: Bottles, Fragments, Pinta, LosslessCut
- **[communications.nix](file:///home/tau/10_PROJECTS/nixOS_move/nixOS_config/modules/flatpaks/communications.nix)**: Whatsie, Viber, Telegram, GoofCord, Discord, NeoChat
- **[workstation.nix](file:///home/tau/10_PROJECTS/nixOS_move/nixOS_config/modules/flatpaks/workstation.nix)**: OBS Studio, BambuStudio, BoxySVG, DesktopEditors (ONLYOFFICE)
- **[waterfox.nix](file:///home/tau/10_PROJECTS/nixOS_move/nixOS_config/modules/flatpaks/waterfox.nix)**: Waterfox browser

---

### 6. Security Modules (`modules/security/`)

- **[secrets.nix](file:///home/tau/10_PROJECTS/nixOS_move/nixOS_config/modules/security/secrets.nix)**: Home-Manager SOPS secrets mapping (`id_ed25519_github`, `id_ed25519_oxford`, `id_ed25519_vps`, `ssh_config`)

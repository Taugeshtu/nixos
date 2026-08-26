# NixOS Move — Active Work

- [[Domain_NixOS]]
- [[Codex]]

## Active Tasks

- [x] **Thunar & Desktop Ergonomics**:
  - [x] Fix right-click context menu (unbound `open-file-menu` in `accels.scm` + restored `keyd` `S-f10`).
  - [x] Enable `programs.thunar.enable = true` and `programs.xfconf.enable = true` for persistent per-folder display settings (`xfconfd`).
  - [x] Add `ffmpeg` and `ffmpegthumbnailer` for custom actions (`gif2mp4`, `strip_to_audio`) and video thumbnails.
  - [x] Move all desktop dotfiles (`mpv`, `niri`, `foot`, `waybar`, `gtklock`, scripts) to pure relative Nix paths.
- [x] **Media Viewers (`mpv`, `imv`)**:
  - [x] Add `mpv` to desktop packages.
  - [x] Reference `imv-dir-respect` directly from GitHub in `flake.nix`.
- [x] **Desktop Notification Daemon / UI**:
  - [x] Wire `swaync` into Niri autostart (`startup.kdl`) and bind toggle to `Mod+Shift+N`.
- [x] **Core CLI / Workflow Binaries**:
  - [x] `to-day` (verify binary under NixOS / nix-ld)
  - [x] `purse` & `purse-niri`
  - [x] `lsp-broker` (systemd user service + unified future build)
  - [x] `Current` (systemd user service + unified future build)
- [x] **Secrets & Disaster Recovery**:
  - [x] Configure `sops-nix` with Age encryption.
  - [x] Encrypt SSH keys into `secrets/secrets.yaml`.
  - [x] Create [bootstrap.sh](file:///home/tau/10_PROJECTS/nixOS_move/bootstrap.sh) with 3-stage head-passphrase recovery & rebuild.
- [x] **MergerFS for K**:
  - [x] Configure mergerfs mount in unlock hook (`~/.source-dirs/K` + `~/.bigK` -> `~/K`).
- [x] **Fast Text Editor**:
  - Package / configure `lite-xl` (super-fast multi-cursor editor) + custom plugins into Nix config.
- [x] **Software Inventory & Triage**:
  - [x] Triage missing GUI and CLI tools from previous Fedora environment.
  - [x] Declarative Flatpaks (`BambuStudio`, `LosslessCut`, `BoxySVG`, `Pinta`, `Flatseal`, `NeoChat`, `Bottles`).
  - [x] Declarative Nix packages (`freecad`, `blender`, `audacity`, `fragments`, `prismlauncher`, `unityhub`, `mutagen`, `uv`, `chafa`, `veracrypt`).


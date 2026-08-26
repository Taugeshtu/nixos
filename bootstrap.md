# Bootstrap

- NixOS bare metal installed on NVMe. Life getting better, still not great.
- Previous Fedora `/etc` backup stored at [/home/tau/00_INGRESS/fedora_etc](file:///home/tau/00_INGRESS/fedora_etc).
- Current home populated with restored dotfiles from old Fedora install.
- Target: incremental migration into home-manager.
- Architecture docs map: [docs/map.md](file:///home/tau/10_PROJECTS/nixOS_move/docs/map.md).
- Shebang rule: If a script is broken or fails to launch, verify shebangs first. Only `#!/usr/bin/env bash` (or `#!/usr/bin/env <interpreter>`) works reliably across NixOS environments.

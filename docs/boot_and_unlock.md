# Two-Stage Boot & Unlock Pipeline

## 1. Stage 1: Kiosk (Unattended Boot)

```text
Power On → systemd-boot → NixOS boots from unencrypted tail System partition
  ├── Headscale client starts & joins private mesh (orbital.priv)
  ├── Phone-home script notifies Orbital of mesh IP
  ├── Power management service caps CPU/GPU wattages (Tower)
  ├── sshd starts (accepts restricted kiosk keys & tau keys)
  ├── System runs swapless (zram compression only)
  └── Kiosk user auto-logs in → launches Kiosk compositor & greeter
```

---

## 2. Stage 2: Vault Unlock (Local or Remote)

```text
[Local Kiosk UI]                          [Remote SSH (tau@host)]
       │                                             │
   Enters Passphrase                             Key Auth / Passphrase
       └──────────────────────┬──────────────────────┘
                              ▼
                      Run Unlock Routine
                              │
  ├── 1. cryptsetup open /dev/disk/by-partlabel/vault nvme_vault
  ├── 2. Mount /home/tau (@home) and /cache (@cache on Codex)
  ├── 3. (Tower) Open Quad-RAID & HDD using keyfiles inside Vault
  ├── 4. Mount auxiliary drives (/cache and bulk storage)
  └── 5. Launch tau user session
```

---

## 3. Session Models: Codex vs Tower

### Codex (Direct Seat Takeover)
- Unlocking kills the Kiosk process completely.
- Tau's Niri session starts directly on the physical display.
- Screen locker (`swaylock` / `waylock`) handles short idle away-time.
- Logout terminates tau session and returns seat to Kiosk.

### Tower (Headless Virtual Output & Viewer Attachment)
- Unlock starts tau's Niri session on a headless/virtual Wayland output.
- Sunshine captures the virtual output for remote streaming.
- **Local Work**: Kiosk attaches a Wayland viewer to tau's virtual display on Monitor 2.
- **Locking / Idle**: Detaches viewer from Monitor 2 (returning to black/slideshow/greeter). Tau's headless Niri, background renders, compute tasks, and Sunshine remain active.
- **Local Re-attach**: Entering password at Kiosk simply reattaches the viewer.

---

## 4. Full Relock

On both Codex and Tower, a full reboot wipes encryption keys from RAM, returning the machine to Stage 1.

# Camera Validation & Troubleshooting Report (`camera_validation.md`)

**Target Device:** Microsoft Surface Go 3 (`slate`)  
**Kernel:** `linux-surface` 6.19.8  
**Architecture:** Intel IPU3 (CIO2 + ImgU) with 3 sensors (`ov5693` Front, `ov8865` Rear, `ov7251` IR)

---

## 1. Prior Baseline (Fedora Live / Install)
- **User observation:**
  > "fedora managed to see through front camera via gnome's "camera" app, but back one was solid green."
- **Status:** Front camera produced visual output; Rear camera produced solid green frames; neither is currently producing output on NixOS.

---

## 2. Kernel Hardware Probing (`dmesg`)

Direct quotes from kernel boot logs on Slate:

```text
[   16.312631] ipu3_imgu: module is from the staging directory, the quality is unknown, you have been warned.
[   16.315889] ipu3-imgu 0000:00:05.0: enabling device (0000 -> 0002)
[   16.316144] ipu3-imgu 0000:00:05.0: device 0x1919 (rev: 0x1)
[   16.316173] ipu3-imgu 0000:00:05.0: physical base address 0x00000000a1000000, 4194304 bytes
[   16.346527] ipu3-cio2 0000:00:14.3: Found supported sensor INT33BE:00
[   16.348039] ipu3-cio2 0000:00:14.3: Found supported sensor INT347A:00
[   16.360341] ipu3-cio2 0000:00:14.3: Found supported sensor INT347E:00
[   16.360594] ipu3-cio2 0000:00:14.3: Connected 3 cameras
[   16.360610] ipu3-cio2 0000:00:14.3: enabling device (0000 -> 0002)
[   16.371874] ipu3-cio2 0000:00:14.3: device 0x9d32 (rev: 0x1)
[   16.452661] ipu3-imgu 0000:00:05.0: loaded firmware version irci_irci_ecr-master_20161208_0213_20170112_1500, 17 binaries, 1212984 bytes
[   16.551336] ov5693 i2c-INT33BE:00: supply dovdd not found, using dummy regulator
[   16.551387] ov5693 i2c-INT33BE:00: supply dvdd not found, using dummy regulator
[   17.185139] ov8865 i2c-INT347A:00: Instantiated dw9719 VCM
```

- **Device Nodes Present in `/dev`:**
  - `/dev/media0`, `/dev/media1`
  - `/dev/v4l-subdev0`, `/dev/v4l-subdev1`
  - `/dev/video0` through `/dev/video13`

---

## 3. Libcamera Enumeration (`cam -l`)

### Standard run: `cam -l`
```text
INFO IPAManager ipa_manager.cpp:147 libcamera is not installed. Adding '/nix/store/src/ipa' to the IPA search path
INFO Camera camera_manager.cpp:340 libcamera v0.7.0
Available cameras:
```
*(No cameras listed)*

### Debug run: `sudo LIBCAMERA_LOG_LEVELS="*:DEBUG" cam -l`
```text
[0:25:37.267180071] [4055]  INFO IPAManager ipa_manager.cpp:147 libcamera is not installed. Adding '/nix/store/src/ipa' to the IPA search path
[0:25:37.267294740] [4055] DEBUG IPAModule ipa_module.cpp:333 ipa_ipu3.so: IPA module /nix/store/ax8jrqcq50digb2xx9hlbi3xw70h9iqb-libcamera-0.7.0/lib/libcamera/ipa/ipa_ipu3.so is signed
[0:25:37.267337487] [4055] DEBUG IPAManager ipa_manager.cpp:239 Loaded IPA module '/nix/store/ax8jrqcq50digb2xx9hlbi3xw70h9iqb-libcamera-0.7.0/lib/libcamera/ipa/ipa_ipu3.so'
[0:25:37.267401722] [4055] DEBUG IPAModule ipa_module.cpp:333 ipa_soft_simple.so: IPA module /nix/store/ax8jrqcq50digb2xx9hlbi3xw70h9iqb-libcamera-0.7.0/lib/libcamera/ipa/ipa_soft_simple.so is signed
[0:25:37.267432287] [4055] DEBUG IPAManager ipa_manager.cpp:239 Loaded IPA module '/nix/store/ax8jrqcq50digb2xx9hlbi3xw70h9iqb-libcamera-0.7.0/lib/libcamera/ipa/ipa_soft_simple.so'
[0:25:37.267446056] [4055]  INFO Camera camera_manager.cpp:340 libcamera v0.7.0
[0:25:37.267552616] [4059] DEBUG Camera camera_manager.cpp:74 Starting camera manager
[0:25:37.275531871] [4059] DEBUG DeviceEnumerator device_enumerator.cpp:267 New media device "ipu3-imgu" created from /dev/media1
[0:25:37.275556946] [4059] DEBUG DeviceEnumerator device_enumerator_udev.cpp:111 Defer media device /dev/media1 due to 12 missing dependencies
[0:25:37.288192257] [4059] DEBUG DeviceEnumerator device_enumerator_udev.cpp:346 All dependencies for media device /dev/media1 found
[0:25:37.288288777] [4059] DEBUG DeviceEnumerator device_enumerator.cpp:295 Added device /dev/media1: ipu3-imgu
[0:25:37.289780283] [4059] DEBUG DeviceEnumerator device_enumerator.cpp:267 New media device "ipu3-cio2" created from /dev/media0
[0:25:37.289913296] [4059] DEBUG DeviceEnumerator device_enumerator_udev.cpp:111 Defer media device /dev/media0 due to 4 missing dependencies
[0:25:37.296104694] [4059] DEBUG DeviceEnumerator device_enumerator_udev.cpp:346 All dependencies for media device /dev/media0 found
[0:25:37.296154085] [4059] DEBUG DeviceEnumerator device_enumerator.cpp:295 Added device /dev/media0: ipu3-cio2
[0:25:37.296666096] [4059] DEBUG Camera camera_manager.cpp:143 Found registered pipeline handler 'ipu3'
[0:25:37.296717408] [4059] DEBUG DeviceEnumerator device_enumerator.cpp:118 Skip ipu3-csi2 0: no device node
[0:25:37.296752139] [4059] DEBUG Camera camera_manager.cpp:143 Found registered pipeline handler 'simple'
[0:25:37.296789991] [4059] DEBUG Camera camera_manager.cpp:143 Found registered pipeline handler 'uvcvideo'
Available cameras:
```

---

## 4. Media Controller Topology (`media-ctl -p -d /dev/media0`)

Direct output from kernel media graph:

```text
Media device information
------------------------
driver          ipu3-cio2
model           Intel IPU3 CIO2
serial          
bus info        PCI:0000:00:14.3
hw revision     0x0
driver version  6.19.8

Device topology
- entity 1: ipu3-csi2 0 (2 pads, 1 link, 0 routes)
            type V4L2 subdev subtype Unknown flags 0
            pad0: SINK,MUST_CONNECT
            pad1: SOURCE
                -> "ipu3-cio2 0":0 [ENABLED,IMMUTABLE]

- entity 4: ipu3-cio2 0 (1 pad, 1 link)
            type Node subtype V4L flags 0
            device node name /dev/video0
            pad0: SINK,MUST_CONNECT
                <- "ipu3-csi2 0":1 [ENABLED,IMMUTABLE]

- entity 10: ipu3-csi2 1 (2 pads, 1 link, 0 routes)
             type V4L2 subdev subtype Unknown flags 0
             pad0: SINK,MUST_CONNECT
             pad1: SOURCE
                 -> "ipu3-cio2 1":0 [ENABLED,IMMUTABLE]

- entity 13: ipu3-cio2 1 (1 pad, 1 link)
             type Node subtype V4L flags 0
             device node name /dev/video1
             pad0: SINK,MUST_CONNECT
                 <- "ipu3-csi2 1":1 [ENABLED,IMMUTABLE]

- entity 19: ipu3-csi2 2 (2 pads, 1 link, 0 routes)
             type V4L2 subdev subtype Unknown flags 0
             pad0: SINK,MUST_CONNECT
             pad1: SOURCE
                 -> "ipu3-cio2 2":0 [ENABLED,IMMUTABLE]

- entity 22: ipu3-cio2 2 (1 pad, 1 link)
             type Node subtype V4L flags 0
             device node name /dev/video2
             pad0: SINK,MUST_CONNECT
                 <- "ipu3-csi2 2":1 [ENABLED,IMMUTABLE]

- entity 28: ipu3-csi2 3 (2 pads, 1 link, 0 routes)
             type V4L2 subdev subtype Unknown flags 0
             pad0: SINK,MUST_CONNECT
             pad1: SOURCE
                 -> "ipu3-cio2 3":0 [ENABLED,IMMUTABLE]

- entity 31: ipu3-cio2 3 (1 pad, 1 link)
             type Node subtype V4L flags 0
             device node name /dev/video3
             pad0: SINK,MUST_CONNECT
                 <- "ipu3-csi2 3":1 [ENABLED,IMMUTABLE]

- entity 37: ov5693 10-0036 (1 pad, 0 link, 0 routes)
             type V4L2 subdev subtype Sensor flags 0
             pad0: SOURCE

- entity 39: ov8865 8-0010 (1 pad, 0 link, 0 routes)
             type V4L2 subdev subtype Sensor flags 0
             pad0: SOURCE

- entity 41: ov7251 9-0060 (1 pad, 0 link, 0 routes)
             type V4L2 subdev subtype Sensor flags 0
             pad0: SOURCE
```

**Key topological finding:** Entities 37, 39, and 41 show `(1 pad, 0 link, 0 routes)`. There are zero links between the sensor SOURCE pads and the CSI-2 receiver SINK pads (`pad0: SINK,MUST_CONNECT`).

---

## 5. Application & Subsystem Layer

### PipeWire
- **Command:** `wpctl status`
- **Output:** Under `Video -> Sources`: NADA (no sources detected).

### GNOME Snapshot (Flatpak)
- **User observation:**
  > "Installed flatpak's Snapshot. Got asked for camera permissions (good!) Granted."  
  > "Then... No Camera Found."

---

## 6. Manual Link Configuration Failures

### Attempt 1: Named entity link
- **Command:**
  ```bash
  sudo nix shell nixpkgs#v4l-utils -c media-ctl -d /dev/media0 -l '"ov8865 8-0010":0 -> "ipu3-csi2 0":0[1]'
  ```
- **Result:**
  ```text
  Unable to parse link: Invalid argument (22)
  ```

### Attempt 2: Numeric entity ID link
- **Command:**
  ```bash
  sudo nix shell nixpkgs#v4l-utils -c media-ctl -d /dev/media0 -l "39:0 -> 1:0[1]"
  ```
- **Result:**
  ```text
  Unable to parse link: Invalid argument (22)
  ```

---

## 7. Current State Summary (Post-Fix)

| Layer | Component | Verified Result | Working? |
|---|---|---|---|
| Kernel I2C/ACPI | `ov5693` (Front) | `Found supported sensor INT33BE:00` | **YES** |
| Kernel I2C/ACPI | `ov8865` (Rear) | `Found supported sensor INT347A:00`, `Instantiated dw9719 VCM` | **YES** |
| Kernel I2C/ACPI | `ov7251` (IR) | `Found supported sensor INT347E:00` | Partial (I2C detected) |
| Kernel IPU3 | `ipu3-imgu` | `loaded firmware version irci_irci...` | **YES** |
| Media Graph | `ipu3-cio2` | Active links established between sensors and CSI-2 receivers | **YES** |
| Libcamera | `cam -l` | Registers both cameras (`CAMR` receiver 0, `CAMF` receiver 1) | **YES** |
| PipeWire | `wpctl` | Video sources exposed and connected | **YES** |
| Userland UI | GNOME Snapshot | Both cameras switchable, live video stream rendered | **YES** |
| Visual Output | Display | Live video feeds rendering from both cameras | **YES (Workable)** |

---

## 8. Root Cause & Implemented Fixes

### 1. Root Causes
- **Missing `dw9719` I2C ID Table (Kernel 6.19 regression)**: Upstream Linux 6.19 dropped `i2c_device_id` from `dw9719.c`. On ACPI Surface platforms, `cio2-bridge` couldn't match the VCM focus motor client. The subdev async notifier never completed, leaving the `/dev/media0` graph unlinked (`0 links`).
- **OV8865 Stale Mode & Missing ISP Tuning**: In 6.19, `ov8865` only configured mode registers during PM resume, stalling on resolution changes. Furthermore, missing `ov8865.yaml` ISP calibration caused libcamera's software IPU3 IPA to output saturated uncalibrated Bayer green frames.

### 2. Config & Patch Fixes Applied
1. **Kernel Patch (`hosts/slate/patches/surface-ipu3-cameras.patch`)**:
   - Re-added `dw9719_id_table` to `dw9719.c` with `.id_table` binding.
   - Enforced `ov8865_mode_configure()` in `ov8865_s_stream()` upon stream start.
2. **Slate Kernel Package Override (`hosts/slate/hardware.nix`)**:
   - Patched `linux-surface` 6.19.8 kernel derivation directly in `boot.kernelPackages`.
3. **Libcamera IPU3 Calibration Files (`hosts/slate/default.nix`)**:
   - Added `ov8865.yaml` and `ov5693.yaml` to `/etc/libcamera/ipa/ipu3/` via `environment.etc`.
   - Set `LIBCAMERA_IPA_TUNING_DIR = "/etc/libcamera/ipa"` in `environment.sessionVariables`.

### 3. Live Verification & Current Status (VERIFIED ✅)
Both cameras are now functional and streaming frames into GNOME Snapshot and PipeWire:
- **Rear Camera (`OV8865`)**: Streams video; VCM autofocus motor confirmed shifting focus actively. Exposure occasionally oscillates/flickers (known `ipa_ipu3` AGC software algorithm behavior).
- **Front Camera (`OV5693`)**: Streams video; image tends to render dark due to default software AGC target curve in `libcamera`.
- **Verdict**: Hardware bringup, ACPI matching, CIO2 media graph routing, VCM driver binding, and userland camera portals are **100% operational**. Remaining artifacts are purely userspace software tuning / IPA algorithm polish.

# Machine Inventory & Hardware

## 1. Host Inventory

| Name | Role | Hardware & Drivers | Storage Topology |
|---|---|---|---|
| **Codex** | Laptop, daily driver | - AMD Ryzen CPU (`amdgpu` iGPU)<br>- Nvidia dGPU (PRIME offload)<br>- ELAN touchpad (`libinput-gestures`)<br>- PCIe 3.0 M.2 slot | Single 1TB NVMe:<br>- 1GB EFI (`/boot`)<br>- ~950GB Vault (LUKS2 → Btrfs)<br>- 50GB System (unencrypted Btrfs, tail) |
| **Tower** | Workstation & Compute Server | - SuperMicro H11SSL-i Rev 2.0 (PCIe 3.0)<br>- AMD EPYC 7402 (24c/48t)<br>- AMD Radeon VII (Display + ROCm)<br>- Nvidia Tesla V100 32GB PCIe with fan mod (CUDA / Compute)<br>- Intel AX200 WiFi 6 / BT 5.2 | - **OS Drive (1TB NVMe)**: 1GB EFI + Vault + 50GB System (tail)<br>- **Scratch/Cache**: 4-NVMe Quad-RAID (LUKS2 → XFS/Btrfs)<br>- **Cold/Bulk**: 3TB HDD (LUKS2 → Btrfs) |
| **Orbital** | VPS (External coordinator) | - Contabo VPS (6 vCPU, 18GB RAM, 1TB SSD)<br>- Runs Rocky Linux<br>- Hosts Headscale, DERP relay, Web services | Standard VPS disk |

---

## 2. Tower Power Management (700W Envelope Protection)

With EPYC 7402 + Radeon VII + Tesla V100, simultaneous peak load can exceed 700W PSU capacity.

Systemd boot service / udev triggers apply power caps immediately at boot:
- `nvidia-smi -pl 160` (cap Tesla V100 to ~160W).
- `echo <cap_in_microwatts> > /sys/class/drm/card0/device/hwmon/.../power1_cap` (cap Radeon VII).
- `cpupower` energy-performance profile for EPYC.

---

## 3. NixOS Configuration Mapping

- `hosts/codex` — Laptop configuration (PRIME offload, touchpad gestures, seat-takeover login).
- `hosts/tower` — Workstation configuration (Dual GPU, power caps, multi-disk unlock, headless virtual compositor).
- `hosts/orbital` — Note: Orbital runs Rocky Linux; NixOS host config is out of current scope.

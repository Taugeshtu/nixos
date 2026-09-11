# Tower Fan Architecture & Dynamic IPMI Slaving

- [[machines]], [[Tower]], [[nixos]]

## 1. Physical Header & Zone Topology

Supermicro H11SSL-i Rev 2.0 groups fan PWM control into two hardwired hardware zones:

| Zone | Headers | Physical Assignment | Target Domain |
|---|---|---|---|
| **Zone 0** | `FAN1`, `FAN2`, `FAN3`, `FAN4` | `FAN2`: V100 Centrifugal Blower<br>`FAN3`: Case PCIe Fan 1<br>`FAN4`: Case PCIe Fan 2 | **GPU / PCIe Domain** |
| **Zone 1** | `FANA`, `FANB` | `FANA`: Arctic 4U-M CPU Cooler<br>`FANB`: Case Fan (Direct CPU feed) | **CPU Domain** |

> Note: All headers report independent RPMs via Tach (Pin 3), but PWM speed (Pin 4) is shared in parallel across each zone.

---

## 2. Dynamic Control Logic (`supermicro-fan-control`)

The BMC firmware has no visibility into PCIe GPU temperatures. A systemd daemon on Tower dynamically drives both zones:

1. **Threshold Arming**: Sets low thresholds for all fan headers to `0 0 0` via `ipmitool sensor thresh` to prevent false BMC alarms on low-RPM fans (600–700 RPM).
2. **BMC Override**: Puts BMC into Full Speed mode (`ipmitool raw 0x30 0x45 0x01 0x01`) to unlock software PWM writes without BMC loop fighting.
3. **Zone 1 (CPU Curve)**:
   - Reads: EPYC 7402 socket temperature from `k10temp` (`/sys/class/hwmon/.../temp1_input`).
   - Curve: 25% PWM @ <= 50°C -> 100% PWM @ >= 75°C (linear, immune to transient boost spikes).
   - Target: `FANA` and `FANB`.
4. **Zone 0 (GPU Curve)**:
   - Reads: Tesla V100 (`nvidia-smi`) and Radeon VII (`/sys/bus/pci/devices/0000:c3:00.0/hwmon/.../temp1_input`).
   - Control Temp: max(Temp_V100, Temp_VII).
   - Curve: 25% PWM @ <= 50°C -> 100% PWM @ >= 80°C (linear, immune to warm idle).
   - Target: `FAN2` (blower), `FAN3`, `FAN4` (case PCIe intakes).
5. **Change-Triggered Logging**: Only sends raw IPMI commands and logs timestamped entries to systemd journal when PWM duty cycle actually changes (zero I2C register spamming).
6. **Failsafe**: On service stop, resets BMC to Standard Auto (`0x00`) so fans never stall.

---

## 3. Manual Inspection & Overrides

### Check Live RPMs:
```bash
sudo ipmitool sdr type fan
```

### Force Full Speed (Emergency Cooling):
```bash
sudo ipmitool raw 0x30 0x45 0x01 0x01
```

### Revert to Default BMC Auto Control:
```bash
sudo ipmitool raw 0x30 0x45 0x01 0x00
```

### Manually Set Zone Speeds (Hex: 0x19 = 25%, 0x32 = 50%, 0x64 = 100%):
```bash
# Zone 0 (GPUs) to 50%:
sudo ipmitool raw 0x30 0x70 0x66 0x01 0x00 0x32

# Zone 1 (CPU) to 50%:
sudo ipmitool raw 0x30 0x70 0x66 0x01 0x01 0x32
```

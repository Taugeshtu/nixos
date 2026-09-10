# Tower Hardware Configuration
# CPU: AMD EPYC / Ryzen (amdgpu / Radeon VII)
# GPU: AMD Radeon VII (amdgpu driver)
{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  # --- Boot modules ---
  boot.initrd.availableKernelModules = [
    "xhci_pci" "nvme" "ahci" "usb_storage" "uas" "sd_mod" "usbhid"
  ];
  boot.initrd.kernelModules = [ "amdgpu" ]; # early KMS for console / Plymouth
  boot.kernelModules = [ "kvm-amd" "uinput" ];

  # --- Hardware Udev & Permissions ---
  hardware.uinput.enable = true;

  # --- CPU microcode & Firmware ---
  hardware.cpu.amd.updateMicrocode =
    lib.mkDefault config.hardware.enableRedistributableFirmware;
  hardware.enableRedistributableFirmware = true;

  # --- Graphics (Radeon VII displays + Tesla V100 compute) ---
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    open = false; # Volta GV100 requires proprietary driver
    powerManagement.enable = false;
    nvidiaPersistenced = true;
    modesetting.enable = true;
    nvidiaSettings = false;
    package = config.boot.kernelPackages.nvidiaPackages.legacy_580;
  };

  # Lock Tesla V100 power limit to 200W on boot
  systemd.services.nvidia-power-limit = {
    description = "Lock Tesla V100 power limit to 200W";
    wantedBy = [ "multi-user.target" ];
    after = [ "nvidia-persistenced.service" ];
    wants = [ "nvidia-persistenced.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${config.hardware.nvidia.package.bin}/bin/nvidia-smi -i 0000:01:00.0 -pl 200";
    };
  };

  # Lock Radeon VII power limit to 200W on boot
  systemd.services.radeon-power-limit = {
    description = "Lock Radeon VII power limit to 200W";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = pkgs.writeShellScript "radeon-power-limit" ''
        for cap in /sys/bus/pci/devices/0000:c3:00.0/hwmon/hwmon*/power1_cap; do
          if [ -w "$cap" ]; then
            echo 200000000 > "$cap"
          fi
        done
      '';
    };
  };

  # --- Filesystems (Mirrors Codex Btrfs + Vfat Layout) ---
  fileSystems."/" = {
    device = "/dev/disk/by-label/NIXSYSTEM";
    fsType = "btrfs";
    options = [ "subvol=@root" "compress=zstd" ];
  };

  fileSystems."/nix" = {
    device = "/dev/disk/by-label/NIXSYSTEM";
    fsType = "btrfs";
    options = [ "subvol=@nix" "compress=zstd" "noatime" ];
  };

  fileSystems."/var/log" = {
    device = "/dev/disk/by-label/NIXSYSTEM";
    fsType = "btrfs";
    options = [ "subvol=@var_log" "nodatacow" ];
  };

  fileSystems."/var/cache" = {
    device = "/dev/disk/by-label/NIXSYSTEM";
    fsType = "btrfs";
    options = [ "subvol=@var_cache" "nodatacow" ];
  };

  fileSystems."/home/kiosk" = {
    device = "/dev/disk/by-label/NIXSYSTEM";
    fsType = "btrfs";
    options = [ "subvol=@kiosk_home" "compress=zstd" ];
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-label/NIXBOOT";
    fsType = "vfat";
    options = [ "fmask=0077" "dmask=0077" ];
  };

  swapDevices = [];
}

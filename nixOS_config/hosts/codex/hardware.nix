# Lenovo IdeaPad 5 Pro 16ACH6 (82L5)
# CPU:   AMD Ryzen 7 5800H (Cezanne)
# iGPU:  AMD Radeon Vega (amdgpu) — drives the display
# dGPU:  NVIDIA GTX 1650 Mobile (PCI:1:0:0) — PRIME offload only
# WiFi:  MediaTek MT7921 (mt7921e + mt76 firmware)
# Touch: ELAN2841:00 04F3:31AD over i2c
{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  # --- Boot modules ---
  boot.initrd.availableKernelModules = [
    "xhci_pci" "nvme" "ahci" "usb_storage" "uas" "sd_mod" "usbhid"
  ];
  boot.initrd.kernelModules = [ "amdgpu" ]; # early KMS — needed for Plymouth / console
  boot.kernelModules = [ "kvm-amd" "uinput" ];

  # --- Hardware Udev & Permissions ---
  hardware.uinput.enable = true;
  services.udev.extraRules = ''
    ACTION!="remove", ATTRS{name}=="ELAN2841:00 04F3:31AD Touchpad", SUBSYSTEM=="input", TAG+="uaccess"
    ACTION!="remove", SUBSYSTEM=="power_supply", ATTR{extensions/ideapad_laptop/conservation_mode}=="*", MODE="0664", GROUP="wheel"
  '';

  systemd.tmpfiles.rules = [
    "z /sys/class/power_supply/BAT0/extensions/ideapad_laptop/conservation_mode 0664 root wheel - -"
  ];


  # --- CPU microcode ---
  hardware.cpu.amd.updateMicrocode =
    lib.mkDefault config.hardware.enableRedistributableFirmware;

  # --- Firmware (MT7921 WiFi needs mt76 blobs) ---
  hardware.enableRedistributableFirmware = true;

  # --- Graphics ---
  hardware.graphics.enable = true;

  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = true;
    powerManagement.finegrained = false;
    open = false;                  # proprietary, not open kernel module
    nvidiaSettings = false;        # GUI tool, skip for now
    package = config.boot.kernelPackages.nvidiaPackages.stable;
    prime = {
      offload.enable = true;
      offload.enableOffloadCmd = true; # adds `nvidia-offload` wrapper
      amdgpuBusId = "PCI:5:0:0";  # 05:00.0 — Radeon Vega (primary display)
      nvidiaBusId  = "PCI:1:0:0"; # 01:00.0 — GTX 1650 (offload only)
    };
  };

  # --- Touchpad ---
  services.libinput.enable = true;

  # --- Filesystems (LVM + Btrfs Layout) ---
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

  # Swap: handled via zram in base.nix and dynamic swapon in unlock.nix post-login
  swapDevices = [];
}

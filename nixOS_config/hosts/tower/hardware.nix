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

  # --- Graphics (Radeon VII - open source amdgpu stack) ---
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
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

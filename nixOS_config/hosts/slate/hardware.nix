# Microsoft Surface Go 3 (8GB RAM / 128GB NVMe)
# CPU:      Intel Pentium Gold 6500Y / Core i3-10100Y (Amber Lake-Y)
# GPU:      Intel UHD Graphics 615 (i915)
# Cameras:  Intel IPU3 (OV5693 front, OV8865 rear) via linux-surface
# Touch:    Intel Precise Touch & Stylus (IPTS) / Elan
{ config, lib, pkgs, modulesPath, inputs, ... }:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    inputs.nixos-hardware.nixosModules.microsoft-surface-go
  ];

  # --- Boot modules & params ---
  boot.kernelParams = [ "acpi_enforce_resources=lax" ];
  boot.initrd.availableKernelModules = [
    "xhci_pci" "nvme" "usb_storage" "sd_mod" "sdhci_pci" "usbhid"
  ];
  boot.initrd.kernelModules = [ "i915" ]; # early KMS for Intel UHD 615
  boot.kernelModules = [ "kvm-intel" "uinput" ];

  # --- Hardware Udev & Permissions ---
  hardware.uinput.enable = true;

  # --- CPU Microcode & Firmware ---
  hardware.cpu.intel.updateMicrocode =
    lib.mkDefault config.hardware.enableRedistributableFirmware;
  hardware.enableRedistributableFirmware = true;

  # --- Graphics & VA-API Video Acceleration ---
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver
      intel-vaapi-driver
      libva-vdpau-driver
      libvdpau-va-gl
    ];
  };

  # --- Touchscreen, Stylus & Touchpad ---
  services.libinput.enable = true;

  # --- Thermal Management & Sensors ---
  services.thermald.enable = true;
  hardware.sensor.iio.enable = true; # iio-sensor-proxy for accelerometer/rotation

  # --- Memory & Swap ---
  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 37;
    memoryMax = 3 * 1024 * 1024 * 1024; # 3 GB
    priority = 100;
  };

  swapDevices = [
    {
      device = "/cache/swapfile";
      size = 20 * 1024; # 20 GB
    }
  ];
}

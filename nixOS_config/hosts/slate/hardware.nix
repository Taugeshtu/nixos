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

  # --- Kernel & Patches (IPU3 camera fixes) ---
  boot.kernelPackages =
    let
      surfacePkg = pkgs.callPackage (inputs.nixos-hardware + "/microsoft/surface/common/kernel/linux-package.nix") { };
      surfacePatches = surfacePkg.surfacePatches {
        version = "6.19.8";
        patchFn = inputs.nixos-hardware + "/microsoft/surface/common/kernel/6.19/patches.nix";
        patchSrc = (pkgs.fetchFromGitHub {
          owner = "linux-surface";
          repo = "linux-surface";
          rev = "bf1921fc63f33d03a007fb38c4f88ff7e7bc1a55";
          hash = "sha256-AV+J1iKpA4PEsX9oVUTGlzGerTWTermia3aJSZxuu/w=";
        }) + "/patches/6.19";
      };
    in
    lib.mkForce (surfacePkg.linuxPackage {
      kernelPatches = surfacePatches ++ [
        {
          name = "surface-ipu3-cameras";
          patch = ./patches/surface-ipu3-cameras.patch;
        }
      ];
      version = "6.19.8";
      sha256 = "sha256-qtpHItuLz6C5cyhRhW1AUIK2pPouOrBnvo2xfN0RWzg=";
      ignoreConfigErrors = true;
    });

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

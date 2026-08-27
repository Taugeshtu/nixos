{ pkgs, inputs, ... }:

{
  imports = [
    ./disko.nix
    ./hardware.nix
    ../../modules/core/base.nix
    ../../modules/core/users.nix
    ../../modules/keyd.nix
    ../../modules/desktop/base.nix
    ../../modules/desktop/theme.nix
    ../../modules/flatpaks/base.nix
    ../../modules/flatpaks/everyday.nix
    ../../modules/flatpaks/communications.nix
    ../../modules/flatpaks/waterfox.nix
  ];

  networking.hostName = "slate";

  # --- Boot & Kernel ---
  boot.blacklistedKernelModules = [ "pcspkr" ];

  # --- Bootloader ---
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 3;
  boot.loader.efi.canTouchEfiVariables = true;

  # --- Bluetooth ---
  hardware.bluetooth.enable = true;
  services.blueman.enable = true;

  # --- Audio & Camera (PipeWire + IPU3 libcamera) ---
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    wireplumber.enable = true;
  };

  # --- Slate Specific Packages (Virtual Keeb, Camera tools, Screen Rotation) ---
  environment.systemPackages = with pkgs; [
    wvkbd
    libcamera
    rot8
  ];

  # --- Security & Auth ---
  security.polkit.enable = true;
  security.sudo.wheelNeedsPassword = true;

  # --- System Services ---
  services.power-profiles-daemon.enable = true;

  # --- Home Manager Integration ---
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.backupFileExtension = "backup";
  home-manager.sharedModules = [
    inputs.sops-nix.homeManagerModules.sops
    ../../modules/security/secrets.nix
  ];
  home-manager.users.tau = import ../../home/tau/default.nix;

  # --- Fonts ---
  fonts.packages = with pkgs; [
    comfortaa
    mononoki
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-color-emoji
  ];

  system.stateVersion = "25.05";
}

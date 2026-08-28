{ pkgs, inputs, ... }:

{
  imports = [
    ./hardware.nix
    ./unlock.nix
    ../../modules/core/base.nix
    ../../modules/core/mesh.nix
    ../../modules/core/users.nix
    ../../modules/keyd.nix
    ../../modules/desktop/base.nix
    ../../modules/desktop/theme.nix
    ../../modules/desktop/future.nix
    ../../modules/desktop/lock.nix
    ../../modules/desktop/workstation.nix
    ../../modules/desktop/gaming.nix
    ../../modules/flatpaks/base.nix
    ../../modules/flatpaks/everyday.nix
    ../../modules/flatpaks/communications.nix
    ../../modules/flatpaks/workstation.nix
    ../../modules/flatpaks/waterfox.nix
    ../../modules/flatpaks/chrome.nix
  ];

  networking.hostName = "codex";

  # --- Kernel ---
  boot.kernelPackages = pkgs.linuxPackages_zen;
  boot.blacklistedKernelModules = [ "pcspkr" ];

  # --- Memory & Swap ---
  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 100;
    memoryMax = 8 * 1024 * 1024 * 1024; # 8 GB
    priority = 100;
  };

  # --- Bootloader ---
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 3;
  boot.loader.efi.canTouchEfiVariables = true;

  # --- Bluetooth ---
  hardware.bluetooth.enable = true;
  services.blueman.enable = true;

  # --- Audio ---
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # --- Security & Auth ---
  security.polkit.enable = true;
  security.sudo.wheelNeedsPassword = true;
  users.users.tau.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDmTvoN2wKMIqhv+5aMqDCcnpQVJ5o5Jpf/ysJ9fMtWD tau@slate"
  ];

  # --- System Services ---
  services.power-profiles-daemon.enable = true;
  systemd.services.nix-daemon.environment.TMPDIR = "/cache/tmp";

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

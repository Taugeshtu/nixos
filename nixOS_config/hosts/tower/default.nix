{ pkgs, lib, inputs, ... }:

{
  imports = [
    ./hardware.nix
    ./unlock.nix
    ./kiosk.nix
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

  networking.hostName = "tower";

  # --- Kernel & Console Rotation ---
  boot.kernelPackages = pkgs.linuxPackages_zen;
  boot.blacklistedKernelModules = [ "pcspkr" ];
  # Rotate framebuffer console 270 deg / 90 counter-clockwise
  boot.kernelParams = [ "fbcon=rotate:3" ];

  # --- Memory & Swap ---
  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 100;
    priority = 100;
  };

  # --- Bootloader ---
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 5;
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
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILKQ22iMgAGp9asehvJgjeK2iG1wUKN0D36S7E4r7H2D tau@codex"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDmTvoN2wKMIqhv+5aMqDCcnpQVJ5o5Jpf/ysJ9fMtWD tau@slate"
  ];
  networking.firewall.allowedTCPPorts = [ 22 ];

  # Auto-prompt for vault unlock on interactive SSH login if locked
  environment.interactiveShellInit = ''
    if [ "$USER" = "tau" ] && [ -n "$SSH_CONNECTION" ] && ! ${pkgs.util-linux}/bin/mountpoint -q /home/tau; then
      echo "=== Tower Vault is locked ==="
      unlock-vault
    fi
  '';

  # --- System Services ---
  services.power-profiles-daemon.enable = true;
  systemd.services.nix-daemon.environment.TMPDIR = "/cache/tmp";

  # --- Streaming & Remote Display (Sunshine Host) ---
  users.users.tau.linger = true;
  services.sunshine = {
    enable = true;
    autoStart = true;
    capSysAdmin = true;
    openFirewall = true;
  };
  systemd.user.services.sunshine.environment.RADV_DEBUG = "novideo";

  # --- Hardware: Supermicro Fan Baseline ---
  boot.kernelModules = [ "ipmi_devintf" "ipmi_si" ];
  environment.systemPackages = [ pkgs.ipmitool ];
  systemd.services.supermicro-fan-quiet = {
    description = "Set Supermicro Fan Thresholds to quiet mode";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "fan-quiet" ''
        for fan in FAN1 FAN2 FAN3 FAN4 FAN5 FANA FANB; do
          ${pkgs.ipmitool}/bin/ipmitool sensor thresh "$fan" lower 0 0 0 || true
        done
        ${pkgs.ipmitool}/bin/ipmitool raw 0x30 0x45 0x01 0x00 || true
      '';
    };
  };

  # Kiosk greeter config is in ./kiosk.nix

  # --- Home Manager Integration ---
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.backupFileExtension = "backup";
  home-manager.sharedModules = [
    inputs.sops-nix.homeManagerModules.sops
    ../../modules/security/secrets.nix
  ];
  home-manager.users.tau = { ... }: {
    imports = [ (import ../../home/tau/default.nix) ];
    xdg.configFile."niri/outputs.kdl".text = ''
      output "HEADLESS-1" {
          mode "1920x1080@60"
          scale 1.0
      }
    '';
  };

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

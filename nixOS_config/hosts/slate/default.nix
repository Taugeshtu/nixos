{ pkgs, inputs, ... }:

{
  imports = [
    ./disko.nix
    ./hardware.nix
    ../../modules/core/base.nix
    ../../modules/core/mesh.nix
    ../../modules/core/users.nix
    ../../modules/keyd.nix
    ../../modules/desktop/base.nix
    ../../modules/desktop/theme.nix
    ../../modules/desktop/future.nix
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
    moonlight-qt
  ];

  # --- IPU3 Libcamera Tuning & Calibration ---
  environment.sessionVariables = {
    LIBCAMERA_IPA_TUNING_DIR = "/etc/libcamera/ipa";
  };
  environment.etc = {
    "libcamera/ipa/ipu3/ov8865.yaml".source = ./libcamera/ov8865.yaml;
    "libcamera/ipa/ipu3/ov5693.yaml".source = ./libcamera/ov5693.yaml;
  };

  # --- Security & Auth ---
  security.polkit.enable = true;
  security.sudo.wheelNeedsPassword = true;
  users.users.tau.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILKQ22iMgAGp9asehvJgjeK2iG1wUKN0D36S7E4r7H2D tau@codex"
  ];

  # --- System Services ---
  services.power-profiles-daemon.enable = true;

  # --- Streaming & Remote Display (Sunshine Host & Moonlight Client) ---
  users.users.tau.linger = true;
  services.sunshine = {
    enable = true;
    autoStart = true;
    capSysAdmin = true;
    openFirewall = true;
  };

  # --- VFS Mounts from Codex ---
  systemd.user.services = let
    mkRcloneMount = remote: mount: {
      description = "Rclone VFS mount for ${remote} to ${mount}";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      wantedBy = [ "default.target" ];
      path = [ "/run/wrappers" pkgs.fuse3 pkgs.fuse pkgs.coreutils ];
      serviceConfig = {
        Type = "simple";
        ExecStartPre = "${pkgs.coreutils}/bin/mkdir -p %h/${mount}";
        ExecStart = "${pkgs.rclone}/bin/rclone mount ${remote} %h/${mount} --allow-other --vfs-cache-mode full --vfs-cache-max-size 10G --vfs-cache-max-age 48h --dir-cache-time 30m";
        ExecStop = "/run/wrappers/bin/fusermount3 -u %h/${mount}";
        Restart = "on-failure";
        RestartSec = "10s";
      };
    };
  in {
    rclone-mount-k = mkRcloneMount "codex:K" "K";
    rclone-mount-p = mkRcloneMount "codex:P" "P";
  };

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
      output "DSI-1" {
          scale 2.0
          transform "normal"
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

{ config, pkgs, lib, inputs, ... }:

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
  systemd.services.supermicro-fan-control = {
    description = "Dynamic Dual-Zone Fan Control (CPU Zone 1, GPU Zone 0)";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" "nvidia-persistenced.service" ];
    path = [ pkgs.ipmitool config.hardware.nvidia.package.bin pkgs.coreutils ];
    serviceConfig = {
      Type = "simple";
      Restart = "always";
      RestartSec = "5s";
      ExecStart = pkgs.writeShellScript "supermicro-fan-control" ''
        for fan in FAN1 FAN2 FAN3 FAN4 FAN5 FANA FANB; do
          ${pkgs.ipmitool}/bin/ipmitool sensor thresh "$fan" lower 0 0 0 || true
        done
        ${pkgs.ipmitool}/bin/ipmitool raw 0x30 0x45 0x01 0x01 || true
        sleep 2

        cleanup() {
          ${pkgs.ipmitool}/bin/ipmitool raw 0x30 0x45 0x01 0x00 || true
          exit 0
        }
        trap cleanup SIGTERM SIGINT EXIT

        last_c=-1; last_g=-1
        while true; do
          c_temp=40
          for d in /sys/class/hwmon/hwmon*; do
            if [ -f "$d/name" ] && [ "$(< "$d/name")" = "k10temp" ] && [ -f "$d/temp1_input" ]; then
              c_temp=$(( $(< "$d/temp1_input") / 1000 )); break
            fi
          done

          r_temp=40
          for f in /sys/bus/pci/devices/0000:c3:00.0/hwmon/hwmon*/temp1_input; do
            if [ -f "$f" ]; then r_temp=$(( $(< "$f") / 1000 )); break; fi
          done
          v_temp=$(${config.hardware.nvidia.package.bin}/bin/nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits 2>/dev/null || echo 40)
          g_temp=$(( v_temp > r_temp ? v_temp : r_temp ))

          # Zone 1 (CPU): 50C->25%, 75C->100% (knee at 50C ignores transient boost spikes)
          if [ "$c_temp" -le 50 ]; then c_pwm=25; elif [ "$c_temp" -ge 75 ]; then c_pwm=100
          else c_pwm=$(( 25 + (c_temp - 50) * 75 / 25 )); fi

          # Zone 0 (GPUs): 40C->25%, 80C->100%
          if [ "$g_temp" -le 40 ]; then g_pwm=25; elif [ "$g_temp" -ge 80 ]; then g_pwm=100
          else g_pwm=$(( 25 + (g_temp - 40) * 75 / 40 )); fi

          # Re-apply and log only when PWM duty cycle actually changes
          if [ "$c_pwm" != "$last_c" ]; then
            echo "[$(date +'%T')] CPU: $c_temp C -> Zone 1: $c_pwm%"
            ${pkgs.ipmitool}/bin/ipmitool raw 0x30 0x70 0x66 0x01 0x01 $(printf "0x%02x" "$c_pwm") >/dev/null 2>&1 || true
            last_c=$c_pwm
          fi
          if [ "$g_pwm" != "$last_g" ]; then
            echo "[$(date +'%T')] GPU: $g_temp C (V100: $v_temp C, VII: $r_temp C) -> Zone 0: $g_pwm%"
            ${pkgs.ipmitool}/bin/ipmitool raw 0x30 0x70 0x66 0x01 0x00 $(printf "0x%02x" "$g_pwm") >/dev/null 2>&1 || true
            last_g=$g_pwm
          fi

          sleep 4
        done
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

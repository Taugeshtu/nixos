# Tower Kiosk: Sway compositor, strikeface auth, moonlight viewer
# Replaces the greetd-based greeter with a persistent kiosk model.
{ pkgs, lib, inputs, config, ... }:

let
  strikefacePkg = inputs.strikeface.packages.${pkgs.system}.default;

  # Kiosk dashboard config: share tau's foot and htop styling
  kioskConfigDir = pkgs.runCommand "kiosk-config" {} ''
    mkdir -p $out/foot $out/htop
    cp ${../../modules/desktop/niri/config/foot/foot.ini} $out/foot/foot.ini
    cp ${../../modules/desktop/niri/config/htop/htoprc} $out/htop/htoprc
  '';

  # Lock script: switches DP-5 back to strikeface on workspace 1
  towerLock = pkgs.writeShellScriptBin "tower-lock" ''
    set -euo pipefail
    if [ -S /run/kiosk-control/sway-ipc.sock ]; then
      ${pkgs.sway}/bin/swaymsg -s /run/kiosk-control/sway-ipc.sock "focus output DP-5; workspace 1; [app_id=greeter-term] focus" || true
    fi
  '';

  # Post-auth script: starts niri if needed, focuses workspace 2 on DP-5
  towerSession = pkgs.writeShellScriptBin "tower-session" ''
    set -euo pipefail

    # 1. Ensure systemd user session has ~/.local/bin in PATH
    ${pkgs.systemd}/bin/systemctl --user set-environment PATH="/home/tau/.local/bin:$PATH"

    # 2. Ensure niri is running (nested in Sway) - start, not restart, to keep session alive
    ${pkgs.systemd}/bin/systemctl --user start niri.service || true

    # 3. Switch DP-5 to workspace 2 (work)
    if [ -S /run/kiosk-control/sway-ipc.sock ]; then
      ${pkgs.sway}/bin/swaymsg -s /run/kiosk-control/sway-ipc.sock "focus output DP-5; workspace 2" || true
    fi
  '';

  # Kiosk-side handler: reads state file, manages moonlight for remote sources (e.g. Codex)
  kioskMoonlightHandler = pkgs.writeShellScript "kiosk-moonlight-handler" ''
    set -euo pipefail

    SOURCE_FILE="/run/kiosk-control/moonlight-source"
    SOURCE=""

    if [ -f "$SOURCE_FILE" ]; then
      SOURCE="$(${pkgs.coreutils}/bin/tr -d '[:space:]' < "$SOURCE_FILE")"
    fi

    SWAYSOCK="/run/kiosk-control/sway-ipc.sock"

    # Kill existing moonlight if running
    ${pkgs.procps}/bin/pkill -u "$(id -u)" -f moonlight 2>/dev/null || true
    sleep 0.5

    if [ -n "$SOURCE" ] && [ "$SOURCE" != "none" ]; then
      echo "Launching moonlight → $SOURCE on workspace 3"
      ${pkgs.sway}/bin/swaymsg -s "$SWAYSOCK" exec "${pkgs.moonlight-qt}/bin/moonlight stream $SOURCE Desktop"
      ${pkgs.sway}/bin/swaymsg -s "$SWAYSOCK" workspace 3 || true
    else
      echo "No source — moonlight detached"
    fi
  '';

  # Kiosk sway config
  kioskSwayConfig = pkgs.writeText "kiosk-sway.conf" ''
    # Share Wayland and IPC sockets with kiosk-control group
    exec ${pkgs.bash}/bin/bash -c '\
      chmod 750 "$XDG_RUNTIME_DIR" && \
      chgrp kiosk-control "$XDG_RUNTIME_DIR" && \
      chmod 660 "$XDG_RUNTIME_DIR/$WAYLAND_DISPLAY" && \
      chgrp kiosk-control "$XDG_RUNTIME_DIR/$WAYLAND_DISPLAY" && \
      chmod 660 "$SWAYSOCK" && \
      chgrp kiosk-control "$SWAYSOCK" && \
      ln -sf "$XDG_RUNTIME_DIR/$WAYLAND_DISPLAY" /run/kiosk-control/sway-wayland.sock && \
      ln -sf "$SWAYSOCK" /run/kiosk-control/sway-ipc.sock'

    # Monitor 1 (Vertical): permanent kiosk status dashboard
    output DP-4 pos 1920 0 res 1920x1080 transform 270

    # Monitor 2 (Horizontal): context-switched work output
    output DP-5 pos 0 0 res 1920x1080 bg #000000 solid_color

    default_border none
    default_floating_border none
    floating_modifier none
    focus_follows_mouse no

    # Assign workspaces to outputs
    workspace 10 output DP-4
    workspace 1 output DP-5
    workspace 2 output DP-5
    workspace 3 output DP-5

    # Assign apps to workspaces (shortcuts_inhibitor on all to prevent key leaks)
    for_window [app_id="kiosk-dashboard"] move to workspace 10, fullscreen enable, shortcuts_inhibitor enable
    for_window [app_id="greeter-term"] move to workspace 1, fullscreen enable, shortcuts_inhibitor enable, focus
    for_window [app_id="(?i).*niri.*"] move to workspace 2, fullscreen enable, shortcuts_inhibitor enable
    for_window [app_id="(?i).*moonlight.*"] move to workspace 3, fullscreen enable, shortcuts_inhibitor enable

    # Launch dashboard on Monitor 1 (vertical, DP-4) with tau's foot & htop theme
    exec ${pkgs.coreutils}/bin/env XDG_CONFIG_HOME=${kioskConfigDir} ${pkgs.foot}/bin/foot --app-id=kiosk-dashboard ${pkgs.htop}/bin/htop

    # Launch strikeface in foot on Monitor 2 (horizontal, DP-5)
    exec ${pkgs.foot}/bin/foot --app-id=greeter-term --override=pad=30x30 /run/wrappers/bin/strikeface --user tau --loop --session ${towerSession}/bin/tower-session
  '';
in
{
  # --- Kiosk control group: tau + kiosk can both read/write the state file ---
  users.groups.kiosk-control = {
    members = [ "tau" "kiosk" ];
  };

  # --- Shared control directory ---
  systemd.tmpfiles.rules = [
    "d /run/kiosk-control 0770 root kiosk-control - -"
  ];

  # --- Strikeface setuid wrapper ---
  security.wrappers.strikeface = {
    source = "${strikefacePkg}/bin/strikeface";
    owner = "root";
    group = "root";
    setuid = true;
  };

  # PAM login service (with vault unlock hook) is defined in unlock.nix

  # --- Greetd: auto-login kiosk user into sway ---
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = lib.mkForce "${pkgs.sway}/bin/sway --config ${kioskSwayConfig}";
        user = lib.mkForce "kiosk";
      };
    };
  };

  # --- Kiosk systemd user units: watch state file, handle moonlight ---
  systemd.user.services.kiosk-moonlight-handler = {
    description = "Handle moonlight source changes";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = kioskMoonlightHandler;
    };
  };

  systemd.user.paths.kiosk-moonlight-watcher = {
    description = "Watch moonlight-source state file";
    wantedBy = [ "default.target" ];
    pathConfig = {
      PathModified = "/run/kiosk-control/moonlight-source";
      Unit = "kiosk-moonlight-handler.service";
    };
  };

  # --- Nested Niri inside Sway ---
  systemd.user.services.niri.environment.WAYLAND_DISPLAY = "/run/kiosk-control/sway-wayland.sock";
  systemd.user.services.niri.environment.PATH = "/home/tau/.local/bin:/run/wrappers/bin:/home/tau/.local/share/flatpak/exports/bin:/var/lib/flatpak/exports/bin:/home/tau/.nix-profile/bin:/nix/profile/bin:/home/tau/.local/state/nix/profile/bin:/etc/profiles/per-user/tau/bin:/nix/var/nix/profiles/default/bin:/run/current-system/sw/bin";
  systemd.user.services.niri.serviceConfig.ExecStart = lib.mkForce [ "" "${pkgs.niri}/bin/niri" ];

  # --- Packages needed on Tower for the kiosk flow ---
  environment.systemPackages = [
    strikefacePkg
    pkgs.foot
    pkgs.sway
    pkgs.moonlight-qt
    towerLock
  ];

  # --- Tower lock & idle bindings: Mod+L and timeout flip to Strikeface ---
  home-manager.users.tau = { lib, ... }: {
    xdg.configFile."swayidle".source = lib.mkForce (pkgs.writeTextDir "config" ''
      timeout 900 '${towerLock}/bin/tower-lock'
      before-sleep '${towerLock}/bin/tower-lock'
    '');

    xdg.configFile."niri/lock.kdl" = lib.mkForce {
      text = ''
        spawn-at-startup "swayidle" "-w"

        binds {
            Mod+L repeat=false cooldown-ms=500 hotkey-overlay-title="[Lock]" { spawn "${towerLock}/bin/tower-lock"; }
        }
      '';
    };
  };
}

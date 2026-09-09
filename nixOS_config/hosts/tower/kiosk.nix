# Tower Kiosk: Sway compositor, strikeface auth, moonlight viewer
# Replaces the greetd-based greeter with a persistent kiosk model.
{ pkgs, lib, inputs, config, ... }:

let
  strikefacePkg = inputs.strikeface.packages.${pkgs.system}.default;

  # Post-auth script: starts niri + sunshine, signals kiosk
  towerSession = pkgs.writeShellScriptBin "tower-session" ''
    set -euo pipefail

    NIRI_SOCKET="''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/niri-socket"

    # 1. Start niri (headless) if not already running
    if ! ${pkgs.procps}/bin/pgrep -u "$(id -u)" -x niri > /dev/null 2>&1; then
      echo "Starting niri (headless)..."
      ${pkgs.coreutils}/bin/setsid ${pkgs.niri}/bin/niri --session > /dev/null 2>&1 &
      disown

      for i in $(seq 1 20); do
        [ -e "$NIRI_SOCKET" ] && break
        sleep 0.25
      done
    fi

    # 2. Start sunshine if not already running
    # TODO: confirm sunshine package and invocation
    # if ! ''${pkgs.procps}/bin/pgrep -u "$(id -u)" -x sunshine > /dev/null 2>&1; then
    #   ''${pkgs.coreutils}/bin/setsid sunshine > /dev/null 2>&1 &
    #   disown
    #   sleep 1
    # fi

    # 3. Tell kiosk to show local niri on monitor 2
    echo "localhost" > /run/kiosk-control/moonlight-source
  '';

  # Kiosk-side handler: reads state file, manages moonlight
  kioskMoonlightHandler = pkgs.writeShellScript "kiosk-moonlight-handler" ''
    set -euo pipefail

    SOURCE_FILE="/run/kiosk-control/moonlight-source"
    SOURCE=""

    if [ -f "$SOURCE_FILE" ]; then
      SOURCE="$(${pkgs.coreutils}/bin/tr -d '[:space:]' < "$SOURCE_FILE")"
    fi

    # Kill existing moonlight if running
    ${pkgs.procps}/bin/pkill -u "$(id -u)" -f moonlight 2>/dev/null || true
    sleep 0.5

    if [ -n "$SOURCE" ]; then
      echo "Launching moonlight → $SOURCE"
      # TODO: confirm moonlight package name and CLI args
      ${pkgs.sway}/bin/swaymsg exec "moonlight stream $SOURCE Desktop"
    else
      echo "No source — moonlight detached"
    fi
  '';

  # Kiosk sway config
  kioskSwayConfig = pkgs.writeText "kiosk-sway.conf" ''
    # Monitor 1 (Vertical): permanent kiosk status dashboard
    output DP-4 pos 1920 0 res 1920x1080 transform 270

    # Monitor 2 (Horizontal): context-switched work output (Strikeface when locked, Moonlight when unlocked)
    output DP-5 pos 0 0 res 1920x1080 bg #000000 solid_color

    default_border none
    default_floating_border none

    # Assign apps to Monitor 2 (horizontal, DP-5)
    for_window [app_id="greeter-term"] move to output DP-5, fullscreen enable, focus
    for_window [app_id="moonlight"] move to output DP-5, fullscreen enable, shortcuts_inhibitor enable

    # Launch strikeface in foot on Monitor 2 (horizontal, DP-5)
    exec ${pkgs.foot}/bin/foot --app-id=greeter-term --override=pad=30x30 /run/wrappers/bin/strikeface --user tau --loop --session ${towerSession}/bin/tower-session

    # TODO: dashboard app on Monitor 1 (vertical, DP-4)
    # exec <dashboard-app>
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

  # --- Packages needed on Tower for the kiosk flow ---
  environment.systemPackages = [
    strikefacePkg
    pkgs.foot
    pkgs.sway
    # TODO: moonlight package
    # pkgs.moonlight-qt
  ];
}

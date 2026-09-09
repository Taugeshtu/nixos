#!/usr/bin/env bash
# kiosk-moonlight-handler: reads moonlight-source state file and acts accordingly
#
# Triggered by systemd path unit watching /run/kiosk-control/moonlight-source
# Runs as the kiosk user (has access to $SWAYSOCK)
#
# State file contents:
#   empty/absent  → no moonlight, strikeface visible on monitor 2
#   "localhost"   → moonlight connecting to Tower's own sunshine (local niri)
#   "<hostname>"  → moonlight connecting to that host (e.g. codex.orbital.priv)

set -euo pipefail

SOURCE_FILE="/run/kiosk-control/moonlight-source"
SOURCE=""

if [ -f "$SOURCE_FILE" ]; then
    SOURCE="$(tr -d '[:space:]' < "$SOURCE_FILE")"
fi

# Kill existing moonlight if running
pkill -u "$(id -u)" -f moonlight 2>/dev/null || true
sleep 0.5

if [ -n "$SOURCE" ]; then
    echo "Launching moonlight → $SOURCE"
    # TODO: confirm exact moonlight CLI invocation
    # moonlight needs: host, app name (Desktop), resolution, etc.
    swaymsg exec "moonlight stream $SOURCE Desktop"
else
    echo "No source — moonlight detached, strikeface visible"
fi

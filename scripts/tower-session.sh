#!/usr/bin/env bash
# tower-session: post-auth script for Tower, run as tau by strikeface
# Usage: strikeface --user tau --loop --session tower-session
#
# Vault unlock is handled by PAM (pam_exec hook on the login service),
# so by the time this script runs, /home/tau is already mounted.
#
# This script is idempotent — safe to run repeatedly.

set -euo pipefail

NIRI_SOCKET="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/niri-socket"

# --- 1. Start niri (headless) if not already running ---
if ! pgrep -u "$(id -u)" -x niri > /dev/null 2>&1; then
    echo "Starting niri (headless)..."
    # TODO: confirm niri headless invocation flags
    # niri renders to a virtual output; sunshine captures it
    setsid niri --session > /dev/null 2>&1 &
    disown

    # Give niri a moment to create its socket
    for i in $(seq 1 20); do
        [ -e "$NIRI_SOCKET" ] && break
        sleep 0.25
    done
fi

# --- 2. Start sunshine if not already running ---
if ! pgrep -u "$(id -u)" -x sunshine > /dev/null 2>&1; then
    echo "Starting sunshine..."
    # TODO: confirm sunshine invocation and config path
    setsid sunshine > /dev/null 2>&1 &
    disown
    sleep 1
fi

# --- 3. Tell kiosk to show local niri on monitor 2 ---
CONTROL_FILE="/run/kiosk-control/moonlight-source"
echo "localhost" > "$CONTROL_FILE"
echo "Wrote 'localhost' to $CONTROL_FILE"

#!/usr/bin/env bash
NODE="/sys/class/power_supply/BAT0/extensions/ideapad_laptop/conservation_mode"

if [ ! -f "$NODE" ]; then
    exit 0
fi

current=$(cat "$NODE")
if [ "$current" -eq 1 ]; then
    echo 0 > "$NODE"
else
    echo 1 > "$NODE"
fi


#!/usr/bin/env bash
# Helper script to toggle Redshift color temperature (Dim / Night Light)

STATE_FILE="/tmp/redshift_active_${USER}"

if [[ -f "$STATE_FILE" ]]; then
    redshift -x &>/dev/null || true
    rm -f "$STATE_FILE"
    command -v notify-send &>/dev/null && notify-send -u low -i display "Night Light" "Mode Normal (6500K)" 2>/dev/null || true
else
    redshift -P -O 5500 &>/dev/null || true
    touch "$STATE_FILE"
    command -v notify-send &>/dev/null && notify-send -u low -i display "Night Light" "Dim Mode Aktif (5500K)" 2>/dev/null || true
fi

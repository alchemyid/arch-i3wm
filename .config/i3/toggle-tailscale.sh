#!/usr/bin/env bash
# Helper script to toggle Tailscale VPN connection with desktop notifications

ACTION="$1"

do_down() {
    tailscale down 2>/dev/null || sudo -n tailscale down 2>/dev/null || sudo tailscale down
    killall -SIGUSR1 i3status 2>/dev/null || true
    command -v notify-send >/dev/null && notify-send -u normal -i network-vpn-disconnected "Tailscale" "VPN Disconnected" 2>/dev/null || true
}

do_up() {
    tailscale up --accept-routes 2>/dev/null || sudo -n tailscale up --accept-routes 2>/dev/null || sudo tailscale up --accept-routes
    killall -SIGUSR1 i3status 2>/dev/null || true
    command -v notify-send >/dev/null && notify-send -u normal -i network-vpn "Tailscale" "VPN Connected" 2>/dev/null || true
}

if [[ "$ACTION" == "down" ]]; then
    do_down
elif [[ "$ACTION" == "up" ]]; then
    do_up
else
    if tailscale status &>/dev/null; then
        do_down
    else
        do_up
    fi
fi

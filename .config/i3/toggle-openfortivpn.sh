#!/usr/bin/env bash
# Helper script to toggle OpenFortiVPN connection with desktop notifications

ACTION="$1"

is_running() {
    pgrep -x openfortivpn >/dev/null || ip link show ppp0 2>/dev/null | grep -q "UP"
}

do_down() {
    sudo systemctl stop openfortivpn@config 2>/dev/null || true
    sudo pkill -SIGINT openfortivpn 2>/dev/null || true
    killall -SIGUSR1 i3status 2>/dev/null || true
    command -v notify-send >/dev/null && notify-send -u normal -i network-vpn-disconnected "OpenFortiVPN" "VPN Disconnected" 2>/dev/null || true
}

do_up() {
    if is_running; then
        command -v notify-send >/dev/null && notify-send -u normal -i network-vpn "OpenFortiVPN" "VPN is already active" 2>/dev/null || true
        return 0
    fi

    if [ -f /etc/openfortivpn/config.conf ]; then
        sudo systemctl start openfortivpn@config
    elif [ -f /etc/openfortivpn/config ]; then
        sudo openfortivpn -c /etc/openfortivpn/config >/dev/null 2>&1 &
    else
        command -v notify-send >/dev/null && notify-send -u critical -i dialog-error "OpenFortiVPN" "Config tidak ditemukan di /etc/openfortivpn/config" 2>/dev/null || true
        return 1
    fi

    killall -SIGUSR1 i3status 2>/dev/null || true
    command -v notify-send >/dev/null && notify-send -u normal -i network-vpn "OpenFortiVPN" "Menghubungkan ke VPN..." 2>/dev/null || true
}

if [[ "$ACTION" == "down" ]]; then
    do_down
elif [[ "$ACTION" == "up" ]]; then
    do_up
else
    if is_running; then
        do_down
    else
        do_up
    fi
fi

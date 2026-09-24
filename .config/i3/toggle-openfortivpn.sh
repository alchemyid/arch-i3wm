#!/usr/bin/env bash
# Helper script to toggle OpenFortiVPN connection with desktop notifications

ACTION="$1"

is_running() {
    pgrep -x openfortivpn >/dev/null || ip link show ppp0 2>/dev/null | grep -q "UP"
}

do_down() {
    # 1. Coba disconnect lewat NetworkManager jika aktif
    NM_ACTIVE=$(nmcli -t -f TYPE,NAME connection show --active 2>/dev/null | grep -E '^vpn:|^fortisslvpn:' | head -n1 | cut -d: -f2)
    if [[ -n "$NM_ACTIVE" ]]; then
        nmcli connection down "$NM_ACTIVE" 2>/dev/null || true
    fi

    # 2. Coba stop via systemd service
    sudo -n systemctl stop openfortivpn@config 2>/dev/null || true

    # 3. Coba pkill proses openfortivpn
    sudo -n pkill -SIGINT openfortivpn 2>/dev/null || pkill -SIGINT openfortivpn 2>/dev/null || true

    killall -SIGUSR1 i3status 2>/dev/null || true
    command -v notify-send >/dev/null && notify-send -u normal -i network-vpn-disconnected "OpenFortiVPN" "VPN Disconnected" 2>/dev/null || true
}

do_up() {
    if is_running; then
        command -v notify-send >/dev/null && notify-send -u normal -i network-vpn "OpenFortiVPN" "VPN sudah dalam keadaan aktif" 2>/dev/null || true
        return 0
    fi

    # Prioritas 1: Jika ada profil NetworkManager bertipe fortisslvpn / vpn
    NM_FORTI=$(nmcli -t -f TYPE,NAME connection show 2>/dev/null | grep -E '^vpn:|^fortisslvpn:' | head -n1 | cut -d: -f2)
    if [[ -n "$NM_FORTI" ]]; then
        nmcli connection up "$NM_FORTI" && {
            killall -SIGUSR1 i3status 2>/dev/null || true
            command -v notify-send >/dev/null && notify-send -u normal -i network-vpn "OpenFortiVPN" "Terhubung ke $NM_FORTI" 2>/dev/null || true
            return 0
        }
    fi

    # Prioritas 2: File config di /etc/openfortivpn/
    CONFIG_FILE=""
    if [ -f /etc/openfortivpn/config ]; then
        CONFIG_FILE="/etc/openfortivpn/config"
    elif [ -f /etc/openfortivpn/config.conf ]; then
        CONFIG_FILE="/etc/openfortivpn/config.conf"
    fi

    if [[ -z "$CONFIG_FILE" ]]; then
        command -v notify-send >/dev/null && notify-send -u critical -i dialog-error "OpenFortiVPN" "File /etc/openfortivpn/config tidak ditemukan!" 2>/dev/null || true
        return 1
    fi

    command -v notify-send >/dev/null && notify-send -u normal -i network-vpn "OpenFortiVPN" "Menghubungkan ke VPN..." 2>/dev/null || true

    # Cek apakah bisa sudo tanpa password (NOPASSWD)
    if sudo -n true 2>/dev/null; then
        if [ -f /etc/openfortivpn/config.conf ]; then
            sudo systemctl start openfortivpn@config
        else
            sudo openfortivpn -c "$CONFIG_FILE" >/dev/null 2>&1 &
        fi
    else
        # Jika butuh password sudo atau input OTP / FortiToken, buka terminal interaktif
        xterm -geometry 80x20 -title "OpenFortiVPN Connect" -e "sudo openfortivpn -c '$CONFIG_FILE'" &
    fi

    sleep 1
    killall -SIGUSR1 i3status 2>/dev/null || true
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

#!/usr/bin/env bash
# Helper script to toggle Bluetooth with auto-connect for trusted devices

if bluetoothctl show | grep -q "Powered: yes"; then
    bluetoothctl power off
    command -v notify-send >/dev/null && notify-send -u low -i bluetooth-disabled "Bluetooth" "Radio Dimatikan (OFF)" 2>/dev/null || true
else
    bluetoothctl power on
    command -v notify-send >/dev/null && notify-send -u low -i bluetooth-active "Bluetooth" "Radio Dinyalakan (Menghubungkan...)" 2>/dev/null || true
    
    # Tunggu 2 detik agar controller Bluetooth siap & PipeWire audio endpoints terdaftar
    (
        sleep 2
        for dev in $(bluetoothctl devices Trusted | awk '{print $2}'); do
            dev_name=$(bluetoothctl info "$dev" | grep "Name:" | cut -d: -f2- | xargs)
            if bluetoothctl connect "$dev" &>/dev/null; then
                command -v notify-send >/dev/null && notify-send -u low -i audio-headset "Bluetooth" "Tersambung ke $dev_name" 2>/dev/null || true
                break
            fi
        done
    ) &
fi

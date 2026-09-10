#!/bin/bash

# Deteksi path sensor temperatur CPU secara dinamis
detect_cpu_temp_path() {
    # 1. Cek tipe thermal zone paling akurat (x86_pkg_temp, coretemp, TCPU, k10temp)
    for t in x86_pkg_temp coretemp TCPU k10temp; do
        for type_file in /sys/class/thermal/thermal_zone*/type; do
            if [[ -f "$type_file" ]] && grep -qi "^$t" "$type_file" 2>/dev/null; then
                local dir
                dir=$(dirname "$type_file")
                if [[ -f "$dir/temp" ]]; then
                    echo "$dir/temp"
                    return 0
                fi
            fi
        done
    done

    # 2. Cek hwmon untuk coretemp / k10temp
    for h in /sys/class/hwmon/hwmon*; do
        if [[ -f "$h/name" ]] && grep -qE "(coretemp|k10temp)" "$h/name" 2>/dev/null; then
            for temp_input in "$h"/temp*_input; do
                if [[ -f "$temp_input" ]]; then
                    echo "$temp_input"
                    return 0
                fi
            done
        fi
    done

    # 3. Fallback ke thermal_zone0 jika ada
    if [[ -f "/sys/class/thermal/thermal_zone0/temp" ]]; then
        echo "/sys/class/thermal/thermal_zone0/temp"
        return 0
    fi
    return 1
}

CONF="$HOME/.config/i3status/bottom.conf"
RUNTIME_CONF="/tmp/i3status_bottom_${USER}.conf"

# Jika file konfigurasi ada, inject sensor path yang valid secara on-the-fly
TEMP_PATH=$(detect_cpu_temp_path)
if [[ -n "$TEMP_PATH" && -f "$CONF" ]]; then
    sed -E "s|path[[:space:]]*=.*|path          = \"$TEMP_PATH\"|" "$CONF" > "$RUNTIME_CONF"
    ACTIVE_CONF="$RUNTIME_CONF"
else
    ACTIVE_CONF="$CONF"
fi

# Eksekusi i3status
i3status -c "$ACTIVE_CONF" | while read line
do
    # 1. Cek status radio Bluetooth dan sesuaikan warna
    if bluetoothctl show | grep -q "Powered: yes"; then
        BT_STAT=" ON"
        BT_COLOR="#b8bb26" # Hijau (color_good)
    else
        BT_STAT=" OFF"
        BT_COLOR="#fb4934" # Merah (color_bad)
    fi

    # 2. Bungkus status Bluetooth ke dalam objek JSON
    BT_JSON="{\"name\":\"bluetooth\",\"full_text\":\"$BT_STAT\",\"color\":\"$BT_COLOR\"}"

    # 3. Bedah dan sisipkan ke aliran data JSON i3status
    if [[ $line == ,\[* ]]; then
        # Baris perulangan normal
        echo ",[$BT_JSON,${line:2}"
    elif [[ $line == \[* ]]; then
        # Baris tembakan pertama saat dimuat
        echo "[$BT_JSON,${line:1}"
    else
        # Baris Header (versi), biarkan lewat
        echo "$line"
    fi
done

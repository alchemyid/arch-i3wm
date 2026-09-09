#!/bin/bash

# Eksekusi i3status
i3status -c ~/.config/i3status/bottom.conf | while read line
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

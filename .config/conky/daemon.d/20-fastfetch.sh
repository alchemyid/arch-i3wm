#!/usr/bin/env bash
# Module to display clean system specs using fastfetch (no logo, no color blocks)

echo "* fastfetch.sh"

# Modul fastfetch yang ditampilkan secara rapi
STRUCTURE="Title:Separator:OS:Host:Kernel:Uptime:Packages:WM:CPU:GPU:Battery"

fastfetch --logo none --pipe -s "$STRUCTURE" 2>/dev/null | while IFS= read -r line; do
    if [[ "$line" =~ ^---+$ ]]; then
        echo " ------------------"
    elif [[ "$line" == *": "* ]]; then
        key="${line%%: *}"
        val="${line#*: }"
        echo " \${color 88ABC4}${key}:\${color} ${val}"
    elif [[ "$line" == *"@"* ]]; then
        echo " \${color fa3}${line}\${color}"
    else
        echo " $line"
    fi
done

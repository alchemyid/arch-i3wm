#!/usr/bin/env python3
import json
import os
import subprocess
import sys

# Jalankan i3status
config_path = os.path.expanduser("~/.config/i3status/top.conf")
proc = subprocess.Popen(
    ["i3status", "-c", config_path],
    stdout=subprocess.PIPE,
    universal_newlines=True
)

def get_tailscale_status():
    try:
        # Pengecekan status resmi tailscale
        res = subprocess.run(
            ["tailscale", "status"],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            timeout=1
        )
        if res.returncode == 0:
            ip = subprocess.check_output(
                ["tailscale", "ip", "-4"],
                stderr=subprocess.DEVNULL,
                timeout=1
            ).decode().strip()
            return {"name": "tailscale", "full_text": f"󰖂 UP ({ip})", "color": "#b8bb26"}
    except Exception:
        pass
    return {"name": "tailscale", "full_text": "󰖂 down", "color": "#fb4934"}

# Teruskan header i3bar
try:
    header = proc.stdout.readline()
    sys.stdout.write(header)
    prefix = proc.stdout.readline()
    sys.stdout.write(prefix)
    sys.stdout.flush()

    while True:
        line = proc.stdout.readline()
        if not line:
            break
        comma = ""
        clean = line.strip()
        if clean.startswith(","):
            comma = ","
            clean = clean[1:]
        try:
            data = json.loads(clean)
            ts = get_tailscale_status()
            # Sisipkan persis sebelum tztime (jam)
            idx = next((i for i, x in enumerate(data) if x.get("name") == "tztime"), len(data))
            data.insert(idx, ts)
            sys.stdout.write(comma + json.dumps(data, ensure_ascii=False) + "\n")
            sys.stdout.flush()
        except Exception:
            sys.stdout.write(line)
            sys.stdout.flush()
except (KeyboardInterrupt, BrokenPipeError):
    pass
finally:
    proc.terminate()

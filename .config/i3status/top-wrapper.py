#!/usr/bin/env python3
import glob
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

def get_interface_ip(ifname):
    """Ambil alamat IPv4 dari antarmuka jaringan."""
    try:
        out = subprocess.check_output(
            ["ip", "-4", "-o", "addr", "show", "dev", ifname],
            stderr=subprocess.DEVNULL,
            timeout=1
        ).decode().strip()
        for line in out.splitlines():
            parts = line.split()
            if len(parts) >= 4 and parts[2] == "inet":
                return parts[3].split("/")[0]
    except Exception:
        pass
    return None

def get_vpn_status():
    """
    Deteksi koneksi VPN multi-protocol:
    - Tailscale
    - OpenFortiVPN (ppp0, ppp*)
    - Wireguard / OpenVPN (wg*, tun*)
    Menghasilkan 1 blok status terpadu di i3bar.
    """
    active_vpns = []

    # 1. Pengecekan Tailscale
    try:
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
            active_vpns.append(f"TS: {ip}" if ip else "TS")
    except Exception:
        pass

    # 2. Pengecekan OpenFortiVPN / PPP (Fortinet SSL-VPN)
    try:
        ppp_devs = glob.glob("/sys/class/net/ppp*")
        for dev in ppp_devs:
            ifname = os.path.basename(dev)
            ip = get_interface_ip(ifname)
            if ip:
                active_vpns.append(f"FORTI: {ip}")
    except Exception:
        pass

    # 3. Pengecekan Wireguard / OpenVPN (wg*, tun* selain tailscale)
    try:
        other_devs = glob.glob("/sys/class/net/tun*") + glob.glob("/sys/class/net/wg*")
        for dev in other_devs:
            ifname = os.path.basename(dev)
            if ifname.startswith("tailscale"):
                continue
            ip = get_interface_ip(ifname)
            if ip:
                active_vpns.append(f"{ifname.upper()}: {ip}")
    except Exception:
        pass

    if active_vpns:
        return {
            "name": "vpn",
            "full_text": "󰖂 " + " | ".join(active_vpns),
            "color": "#b8bb26"
        }
    return {
        "name": "vpn",
        "full_text": "󰖂 VPN down",
        "color": "#fb4934"
    }

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
            vpn_block = get_vpn_status()
            # Sisipkan persis sebelum tztime (jam)
            idx = next((i for i, x in enumerate(data) if x.get("name") == "tztime"), len(data))
            data.insert(idx, vpn_block)
            sys.stdout.write(comma + json.dumps(data, ensure_ascii=False) + "\n")
            sys.stdout.flush()
        except Exception:
            sys.stdout.write(line)
            sys.stdout.flush()
except (KeyboardInterrupt, BrokenPipeError):
    pass
finally:
    proc.terminate()

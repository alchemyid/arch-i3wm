xrdb -merge ~/.Xresources

# Daftarkan environment display X11 ke D-Bus dan systemd user session
if command -v dbus-update-activation-environment >/dev/null 2>&1; then
    dbus-update-activation-environment --systemd DISPLAY XAUTHORITY
fi

exec i3 > /dev/null 2>&1

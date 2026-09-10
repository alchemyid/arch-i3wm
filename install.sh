#!/usr/bin/env bash
# ==============================================================================
# Arch Linux + i3wm Setup & Dependency Installer
# Automated provisioning script for fresh Arch Linux installation
# ==============================================================================

set -eo pipefail

# --- Warna Output ---
C_RESET="\e[0m"
C_BOLD="\e[1m"
C_GREEN="\e[32m"
C_BLUE="\e[34m"
C_YELLOW="\e[33m"
C_RED="\e[31m"
C_CYAN="\e[36m"

log_info()    { echo -e "${C_BLUE}${C_BOLD}[INFO]${C_RESET} $*"; }
log_success() { echo -e "${C_GREEN}${C_BOLD}[OK]${C_RESET} $*"; }
log_warn()    { echo -e "${C_YELLOW}${C_BOLD}[WARN]${C_RESET} $*"; }
log_error()   { echo -e "${C_RED}${C_BOLD}[ERROR]${C_RESET} $*"; }
log_step()    { echo -e "\n${C_CYAN}${C_BOLD}==>${C_RESET} ${C_BOLD}$*${C_RESET}"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ------------------------------------------------------------------------------
# 1. Pre-flight Checks
# ------------------------------------------------------------------------------
log_step "Memeriksa lingkungan eksekusi..."

if [[ "$EUID" -eq 0 ]]; then
    log_error "Script TIDAK boleh dijalankan sebagai root / sudo langsung!"
    log_error "Jalankan sebagai user biasa: ./install.sh (sudo prompt akan diminta otomatis)."
    exit 1
fi

# Pastikan sudo tersedia
if ! command -v sudo >/dev/null 2>&1; then
    log_error "Perintah 'sudo' tidak ditemukan. Pasang sudo dan berikan izin wheel terlebih dahulu."
    exit 1
fi

# Refresh sudo timestamp
sudo -v
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

# ------------------------------------------------------------------------------
# 2. Daftar Dependensi Paket Arch Linux (Official Repo)
# ------------------------------------------------------------------------------
log_step "Menyiapkan daftar paket dependensi..."

PKGS_BASE=(
    base-devel
    git
    curl
    wget
)

PKGS_XORG=(
    xorg-server
    xorg-xinit
    xorg-xrdb
    xorg-xset
    xf86-input-libinput
    xorg-xinput
)

PKGS_I3WM=(
    i3-wm
    i3status
    dmenu
)

PKGS_TERMINAL_SHELL=(
    xterm
    ttf-jetbrains-mono-nerd
    zsh
    zsh-autosuggestions
    zsh-syntax-highlighting
    neovim
    openssh
)

PKGS_HARDWARE_AUDIO_NET=(
    networkmanager
    network-manager-applet
    pipewire
    pipewire-pulse
    pipewire-alsa
    wireplumber
    bluez
    bluez-utils
    brightnessctl
    tailscale
)

PKGS_UTILITIES=(
    feh
    dex
    xss-lock
    scrot
    imagemagick
    maim
    xclip
    libnotify
    picom
    redshift
)

PKGS_DEV_BROWSERS=(
    nodejs
    npm
    firefox
)

# Gabungkan seluruh paket resmi
ALL_OFFICIAL_PKGS=(
    "${PKGS_BASE[@]}"
    "${PKGS_XORG[@]}"
    "${PKGS_I3WM[@]}"
    "${PKGS_TERMINAL_SHELL[@]}"
    "${PKGS_HARDWARE_AUDIO_NET[@]}"
    "${PKGS_UTILITIES[@]}"
    "${PKGS_DEV_BROWSERS[@]}"
)

# ------------------------------------------------------------------------------
# 3. Update Mirror & Install Paket Resmi
# ------------------------------------------------------------------------------
log_step "Memperbarui database pacman dan menginstal paket resmi..."

sudo pacman -Sy --needed --noconfirm "${ALL_OFFICIAL_PKGS[@]}"
log_success "Semua paket resmi berhasil dipasang!"

# ------------------------------------------------------------------------------
# 4. Deteksi / Pasang AUR Helper (yay)
# ------------------------------------------------------------------------------
log_step "Memeriksa AUR Helper..."

AUR_HELPER=""
if command -v yay >/dev/null 2>&1; then
    AUR_HELPER="yay"
elif command -v paru >/dev/null 2>&1; then
    AUR_HELPER="paru"
else
    log_info "AUR helper tidak ditemukan. Mengunduh dan meng-compile yay..."
    TEMP_DIR=$(mktemp -d)
    git clone https://aur.archlinux.org/yay.git "$TEMP_DIR/yay"
    (cd "$TEMP_DIR/yay" && makepkg -si --noconfirm)
    rm -rf "$TEMP_DIR"
    AUR_HELPER="yay"
fi

log_success "AUR Helper siap digunakan: $AUR_HELPER"

# ------------------------------------------------------------------------------
# 5. Pasang Paket AUR (i3lock-color)
# ------------------------------------------------------------------------------
log_step "Memasang dependensi dari AUR..."

PKGS_AUR=(
    i3lock-color
    google-chrome
)

for pkg in "${PKGS_AUR[@]}"; do
    if pacman -Qi "$pkg" >/dev/null 2>&1; then
        log_info "Paket AUR '$pkg' sudah terpasang."
    else
        log_info "Memasang paket AUR '$pkg' via $AUR_HELPER..."
        $AUR_HELPER -S --needed --noconfirm "$pkg"
    fi
done

log_success "Paket AUR berhasil dipasang!"

# ------------------------------------------------------------------------------
# 6. Setup Helper Script (/usr/local/bin/toggle-tailscale) & Sudoers NOPASSWD
# ------------------------------------------------------------------------------
log_step "Mengonfigurasi helper toggle-tailscale dan izin sudoers..."

# Helper script dengan deteksi IP aktif dan parameter opsional
sudo bash -c 'cat << "EOF" > /usr/local/bin/toggle-tailscale
#!/usr/bin/env bash
# Helper script to toggle Tailscale VPN connection with desktop notifications

ACTION="$1"

do_down() {
    tailscale down 2>/dev/null || sudo -n tailscale down 2>/dev/null || sudo tailscale down
    command -v notify-send >/dev/null && notify-send -u normal -i network-vpn-disconnected "Tailscale" "VPN Disconnected"
}

do_up() {
    tailscale up --accept-routes 2>/dev/null || sudo -n tailscale up --accept-routes 2>/dev/null || sudo tailscale up --accept-routes
    command -v notify-send >/dev/null && notify-send -u normal -i network-vpn "Tailscale" "VPN Connected"
}

if [[ "$ACTION" == "down" ]]; then
    do_down
elif [[ "$ACTION" == "up" ]]; then
    do_up
else
    if tailscale ip -4 &>/dev/null; then
        do_down
    else
        do_up
    fi
fi
EOF'
sudo chmod +x /usr/local/bin/toggle-tailscale
log_success "Script /usr/local/bin/toggle-tailscale siap digunakan."

# Berikan izin NOPASSWD untuk tailscale agar shortcut i3 tidak meminta password
log_info "Menambahkan izin NOPASSWD tailscale ke /etc/sudoers.d/10-tailscale..."
sudo bash -c 'echo "%wheel ALL=(ALL) NOPASSWD: /usr/bin/tailscale, /usr/local/bin/toggle-tailscale" > /etc/sudoers.d/10-tailscale'
sudo chmod 440 /etc/sudoers.d/10-tailscale

# Set Tailscale operator ke user saat ini jika tailscaled aktif
if systemctl is-active --quiet tailscaled.service 2>/dev/null; then
    sudo tailscale set --operator="$USER" 2>/dev/null || true
fi

# Berikan izin ke grup video & input untuk kontrol kecerahan layar
log_info "Menambahkan user $USER ke grup video dan input (brightnessctl)..."
sudo usermod -aG video,input "$USER" 2>/dev/null || true

# Pastikan Bluetooth tidak boros baterai saat boot (hanya aktif saat dipanggil)
log_info "Mengonfigurasi Bluetooth AutoEnable=false..."
sudo sed -i 's/#AutoEnable=true/AutoEnable=false/' /etc/bluetooth/main.conf 2>/dev/null || true

# ------------------------------------------------------------------------------
# 7. Setup Konfigurasi Touchpad (Tap-to-Click & Natural Scrolling)
# ------------------------------------------------------------------------------
log_step "Mengonfigurasi Touchpad (Tap-to-Click & Natural Scrolling)..."

sudo mkdir -p /etc/X11/xorg.conf.d
sudo bash -c 'cat << "EOF" > /etc/X11/xorg.conf.d/30-touchpad.conf
Section "InputClass"
    Identifier "touchpad"
    Driver "libinput"
    MatchIsTouchpad "on"
    Option "Tapping" "on"
    Option "TappingDrag" "on"
    Option "NaturalScrolling" "true"
    Option "ScrollMethod" "twofinger"
    Option "DisableWhileTyping" "on"
EndSection
EOF'
log_success "Konfigurasi /etc/X11/xorg.conf.d/30-touchpad.conf berhasil diterapkan."

# ------------------------------------------------------------------------------
# 8. Aktifkan Layanan Systemd (Services)
# ------------------------------------------------------------------------------
log_step "Mengaktifkan layanan systemd..."

SERVICES=(
    NetworkManager.service
    bluetooth.service
    tailscaled.service
)

for srv in "${SERVICES[@]}"; do
    log_info "Mengaktifkan $srv..."
    sudo systemctl enable "$srv"
    sudo systemctl start "$srv" || log_warn "Gagal memulai $srv (akan aktif saat reboot)"
done

log_success "Layanan systemd dikonfigurasi!"

# ------------------------------------------------------------------------------
# 8. Deploy & Sinkronisasi Konfigurasi (Dotfiles)
# ------------------------------------------------------------------------------
log_step "Menyinkronkan file konfigurasi ke \$HOME ($HOME)..."

mkdir -p "$HOME/.config/i3"
mkdir -p "$HOME/.config/i3status"
mkdir -p "$HOME/Pictures"

# Helper fungsi backup & copy/link
deploy_file() {
    local src="$1"
    local dest="$2"

    if [[ -f "$dest" || -L "$dest" ]]; then
        if cmp -s "$src" "$dest"; then
            log_info "Sudah sesuai: $dest"
            return
        fi
        local backup="${dest}.bak.$(date +%s)"
        log_warn "File $dest sudah ada, membuat backup: $backup"
        cp -a "$dest" "$backup"
    fi

    cp -a "$src" "$dest"
    log_success "Disalin: $src -> $dest"
}

# Deploy root dotfiles
deploy_file "$SCRIPT_DIR/.xinitrc" "$HOME/.xinitrc"
deploy_file "$SCRIPT_DIR/.Xresources" "$HOME/.Xresources"
deploy_file "$SCRIPT_DIR/.zshrc" "$HOME/.zshrc"

# Deploy i3 configs
deploy_file "$SCRIPT_DIR/.config/i3/config" "$HOME/.config/i3/config"
deploy_file "$SCRIPT_DIR/.config/i3/lock.sh" "$HOME/.config/i3/lock.sh"
deploy_file "$SCRIPT_DIR/.config/i3/toggle-bluetooth.sh" "$HOME/.config/i3/toggle-bluetooth.sh"
deploy_file "$SCRIPT_DIR/.config/i3/toggle-redshift.sh" "$HOME/.config/i3/toggle-redshift.sh"
deploy_file "$SCRIPT_DIR/.config/i3/toggle-tailscale.sh" "$HOME/.config/i3/toggle-tailscale.sh"

# Deploy i3status configs
deploy_file "$SCRIPT_DIR/.config/i3status/top.conf" "$HOME/.config/i3status/top.conf"
deploy_file "$SCRIPT_DIR/.config/i3status/top-wrapper.py" "$HOME/.config/i3status/top-wrapper.py"
deploy_file "$SCRIPT_DIR/.config/i3status/bottom.conf" "$HOME/.config/i3status/bottom.conf"
deploy_file "$SCRIPT_DIR/.config/i3status/wrapper.sh" "$HOME/.config/i3status/wrapper.sh"

# Pastikan script dapat dieksekusi
chmod +x "$HOME/.config/i3/lock.sh"
chmod +x "$HOME/.config/i3/toggle-bluetooth.sh"
chmod +x "$HOME/.config/i3/toggle-redshift.sh"
chmod +x "$HOME/.config/i3/toggle-tailscale.sh"
chmod +x "$HOME/.config/i3status/top-wrapper.py"
chmod +x "$HOME/.config/i3status/wrapper.sh"

# Load Xresources jika di sesi X
if [[ -n "$DISPLAY" ]]; then
    xrdb -merge "$HOME/.Xresources" 2>/dev/null || true
fi

# Placeholder wallpaper jika belum ada gambar
if [[ ! -f "$HOME/Pictures/wallpaper.jpg" ]]; then
    log_warn "Wallpaper belum ditemukan di $HOME/Pictures/wallpaper.jpg"
    log_info "Membuat placeholder wallpaper dengan ImageMagick..."
    convert -size 1920x1080 xc:"#282828" \
        -gravity center -pointsize 48 -fill "#ebdbb2" \
        -annotate +0+0 "Arch Linux + i3wm" \
        "$HOME/Pictures/wallpaper.jpg" 2>/dev/null || true
fi

# ------------------------------------------------------------------------------
# 9. Konfigurasi Shell (Zsh)
# ------------------------------------------------------------------------------
log_step "Memeriksa shell default user..."

CURRENT_SHELL="$(basename "$SHELL")"
if [[ "$CURRENT_SHELL" != "zsh" ]]; then
    log_info "Mengubah shell default ke zsh untuk user $USER..."
    ZSH_PATH="$(which zsh)"
    chsh -s "$ZSH_PATH" "$USER" || log_warn "Gagal mengubah shell dengan chsh otomatis. Jalankan: chsh -s $(which zsh)"
else
    log_info "Shell default sudah menggunakan zsh."
fi

# ------------------------------------------------------------------------------
# Selesai
# ------------------------------------------------------------------------------
echo -e "\n${C_GREEN}${C_BOLD}======================================================${C_RESET}"
echo -e "${C_GREEN}${C_BOLD}   INSTALASI & KONFIGURASI SELESAI DENGAN SUKSES!    ${C_RESET}"
echo -e "${C_GREEN}${C_BOLD}======================================================${C_RESET}"
echo -e "Catatan penting:"
echo -e " 1. Mulai X session dengan perintah: ${C_CYAN}startx${C_RESET}"
echo -e " 2. Letakkan wallpaper pilihan Anda di: ${C_CYAN}$HOME/Pictures/wallpaper.jpg${C_RESET}"
echo -e " 3. Jalankan login Tailscale: ${C_CYAN}sudo tailscale up${C_RESET}"
echo -e " 4. Reboot sistem disarankan jika baru pertama kali memasang driver & audio."
echo ""

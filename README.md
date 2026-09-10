# Arch Linux + i3wm Dotfiles & Automation

Dokumentasi arsitektur, dependensi paket, konfigurasi perangkat keras, dan panduan otomasi instalasi ulang untuk lingkungan desktop **Arch Linux + i3wm** (dioptimalkan untuk laptop HP ProBook / Intel Graphics).

---

## 1. Analisa Konfigurasi Sistem & File

Berikut adalah pembedahan teknis seluruh komponen konfigurasi yang ada di dalam repositori ini:

### A. Display Server & X11
* **File:** [`.xinitrc`](file:///home/girirahayu/arch-i3wm/.xinitrc)
  * Menjalankan `xrdb -merge ~/.Xresources` untuk memuat basis data styling X11.
  * Menjalankan `exec i3 > /dev/null 2>&1` sebagai sesi window manager utama saat `startx` dieksekusi.
* **File:** [`.Xresources`](file:///home/girirahayu/arch-i3wm/.Xresources)
  * Font terminal: `JetBrainsMono Nerd Font` ukuran **9**.
  * Skema warna: **Gruvbox Dark** (kontras lembut dan ramah di mata).
  * Pengaturan buffer clipboard Xterm (`Ctrl+Shift+C` untuk copy dan `Ctrl+Shift+V` untuk paste).

### B. Shell & Lingkungan Terminal
* **File:** [`.zshrc`](file:///home/girirahayu/arch-i3wm/.zshrc)
  * Shell: **Zsh** dengan prompt dinamis yang mendeteksi status X11 (`$DISPLAY`) dan git branch (`vcs_info`).
  * Plugin aktif:
    * `zsh-autosuggestions` (rekomendasi perintah otomatis dari history).
    * `zsh-syntax-highlighting` (pewarnaan sintaks CLI interaktif).
  * Alias penting:
    * `vim` diarahkan ke `nvim` (`neovim`), dengan variabel lingkungan `EDITOR=vim` dan `VISUAL=vim`.
    * `nerdctl` fungsi remote execution container via `ssh`.
    * `k` (`kubectl`), `tf` (`terraform`), `ll` (`ls -lah`), `startx`.

### C. Window Manager (i3wm)
* **File:** [`.config/i3/config`](file:///home/girirahayu/arch-i3wm/.config/i3/config)
  * **Mod Key:** `Mod4` (Tombol **Super / Windows**).
  * **Font Global:** `JetBrainsMono Nerd Font 9` untuk seluruh judul jendela (*window title*) dan bar.
  * **Compositor (Anti-Tearing):** `picom -b` dijalankan saat startup untuk mengeliminasi screen tearing, flickering, dan micro-stutter pada layar laptop.
  * **Wallpaper:** Ditangani oleh `feh --bg-scale ~/Pictures/wallpaper.jpg`.
  * **Kecerahan Layar (Backlight):** Menggunakan `brightnessctl` via tombol fungsi laptop (`XF86MonBrightnessUp/Down`).
  * **Audio Control:** Menggunakan `pactl` (PipeWire PulseAudio) dengan auto-refresh sinyal `SIGUSR1` ke status bar.
  * **Screenshot:** Menggunakan `maim` + `xclip`:
    * `Print`: Seleksi area screenshot langsung ke clipboard.
    * `Mod + Print`: Screenshot seluruh layar langsung ke clipboard.
  * **Startup Defaults:**
    * Radio Bluetooth otomatis dimatikan saat boot (`bluetoothctl power off`).
    * Tailscale VPN otomatis dimatikan saat boot (`toggle-tailscale.sh down`).

### D. Fitur Layar Kunci (Screen Lock & Auto-Lock)
* **File:** [`.config/i3/lock.sh`](file:///home/girirahayu/arch-i3wm/.config/i3/lock.sh)
  * **Shortcut Manual:** **`Mod + Shift + x`**.
  * **Auto-Lock (Idle & Suspend):** Dikelola oleh `xset s 300 300` dan `xss-lock`. Layar otomatis terkunci jika laptop didiamkan selama **5 menit** (300 detik) atau saat layar laptop ditutup (*sleep/suspend*).
  * **Mekanisme Kunci:** Mengambil screenshot via `scrot`, mengaburkan (*blur*) gambar dengan `convert` (ImageMagick), lalu menjalankan **`i3lock-color`** (AUR) dengan cincin indikator dan jam bertema Gruvbox.
  * **Membuka Kunci (*Unlock*):** Cukup ketikkan **password akun user Anda**, lalu tekan tombol **Enter**.

### E. Skrip Helper Otomasi (Toggle Scripts)
* **File:** [`.config/i3/toggle-bluetooth.sh`](file:///home/girirahayu/arch-i3wm/.config/i3/toggle-bluetooth.sh)
  * **Shortcut:** **`Mod + b`**.
  * Menyalakan/mematikan radio Bluetooth. Saat dinyalakan, skrip otomatis memberi jeda 2 detik (menunggu controller & audio PipeWire siap) lalu **otomatis menyambungkan ke headset/speaker paired (*WZ-BT5.0*)** lengkap dengan notifikasi desktop, tanpa perlu membuka terminal lagi.
* **File:** [`.config/i3/toggle-tailscale.sh`](file:///home/girirahayu/arch-i3wm/.config/i3/toggle-tailscale.sh)
  * **Shortcut:** **`Mod + t`**.
  * Menghubungkan atau memutuskan VPN Tailscale ke homelab secara instan tanpa dialog password sudo, serta mengirim sinyal pembaruan status ke bar atas.
* **File:** [`.config/i3/toggle-redshift.sh`](file:///home/girirahayu/arch-i3wm/.config/i3/toggle-redshift.sh)
  * **Shortcut:** **`Mod + n`**.
  * Mengaktifkan filter cahaya biru / mode malam **5500K** via `redshift` untuk meredakan mata lelah dan pusing. Tekan kembali untuk mengembalikan ke temperatur normal (6500K).

### F. Status Bar Ganda (Dual i3bar)
* **Top Bar (Bar Atas):**
  * Konfigurasi: [`.config/i3status/top.conf`](file:///home/girirahayu/arch-i3wm/.config/i3status/top.conf)
  * Wrapper Script: [`.config/i3status/top-wrapper.py`](file:///home/girirahayu/arch-i3wm/.config/i3status/top-wrapper.py)
  * Menampilkan: Penggunaan RAM, Disk Root (`/`), Disk Data (`/home`), **Status Tailscale VPN Dinamis** (`󰖂 UP (IP)` warna hijau atau `󰖂 down` warna merah tanpa terpengaruh bug link-local IPv6 `fe80::...`), Jam/Kalender, dan Persentase Baterai.
* **Bottom Bar (Bar Bawah):**
  * Konfigurasi: [`.config/i3status/bottom.conf`](file:///home/girirahayu/arch-i3wm/.config/i3status/bottom.conf)
  * Wrapper Script: [`.config/i3status/wrapper.sh`](file:///home/girirahayu/arch-i3wm/.config/i3status/wrapper.sh)
  * Menampilkan: **Status Bluetooth Dinamis** (` ON` warna hijau atau ` OFF` warna merah), Koneksi WiFi, Ethernet LAN, Beban CPU (%), dan Temperatur CPU (°C).

### G. Konfigurasi Touchpad (Trackpad)
* **File Sistem:** `/etc/X11/xorg.conf.d/30-touchpad.conf`
  * Dikelola oleh driver `libinput` untuk touchpad laptop HP ProBook (`ELAN0733`).
  * **Tapping (Tap-to-click):** Sentuh ringan 1 jari untuk klik kiri, 2 jari untuk klik kanan, 3 jari untuk klik tengah.
  * **Tapping Drag:** Sentuh ganda dan geser untuk seleksi teks / drag window.
  * **Natural Scrolling & Dua Jari:** Arah scroll dua jari natural seperti layar sentuh.
  * **Disable While Typing:** Otomatis menonaktifkan trackpad saat mengetik untuk mencegah kursor meloncat.

---

## 2. Matriks Paket & Dependensi

| Kategori | Paket (Arch Linux Repo) | Sumber | Fungsi / Keterangan |
| :--- | :--- | :--- | :--- |
| **X11 / Display** | `xorg-server`, `xorg-xinit`, `xorg-xrdb`, `xorg-xset` | Official | Display server dasar, `startx`, parser `.Xresources`, pengatur screen timeout idle |
| **Touchpad / Input** | `xf86-input-libinput`, `xorg-xinput` | Official | Driver trackpad libinput (Tap-to-click, gestures, natural scrolling) |
| **Window Manager** | `i3-wm`, `i3status`, `dmenu` | Official | Tiling window manager, generator status bar, launcher menu aplikasi |
| **Base / Core Tools** | `base-devel`, `git`, `curl`, `wget`, `psmisc` | Official | Paket esensial sistem, kompilasi software, dan utilitas proses (`killall`) |
| **Typography & Fonts**| `ttf-jetbrains-mono-nerd`, `noto-fonts`, `noto-fonts-emoji`, `ttf-liberation` | Official | JetBrainsMono Nerd Font (ikon/status bar), fallback Unicode, emoji warna, & metrik standar |
| **Terminal & Shell** | `xterm`, `zsh`, `zsh-autosuggestions`, `zsh-syntax-highlighting` | Official | Terminal emulator & interactive shell dengan rekomendasi perintah dan syntax highlight |
| **Editor & Git** | `neovim`, `git`, `openssh` | Official | Editor default (`vim` -> `nvim`), version control, dan remote terminal |
| **Programming & Dev** | `nodejs`, `npm`, `go`, `rust` | Official | Runtime Node.js & npm, compiler Go (Golang), serta toolchain Rust & Cargo |
| **Web Browser** | `firefox` | Official | Web browser open-source default |
| **Web Browser (AUR)** | `google-chrome` | **AUR** | Web browser Google Chrome Stable |
| **Wallpaper & Desktop** | `feh`, `dex`, `picom` | Official | Background manager, autostart XDG, dan compositor pencegah screen tearing |
| **Layar Kunci** | `xss-lock`, `scrot`, `imagemagick` | Official | Idle suspend listener, screen capture, dan efek pengabur blur gambar |
| **Layar Kunci (AUR)** | `i3lock-color` | **AUR** | Versi i3lock khusus dengan indikator cincin jam & palet hex Gruvbox |
| **Audio Modern** | `pipewire`, `pipewire-pulse`, `wireplumber` | Official | Audio server modern pengganti PulseAudio, kompatibel dengan `pactl` |
| **Network & VPN** | `networkmanager`, `network-manager-applet`, `tailscale` | Official | Pengelola WiFi/LAN, ikon tray sistem, dan mesh VPN Tailscale |
| **Hardware Control** | `bluez`, `bluez-utils`, `brightnessctl` | Official | Bluetooth daemon & CLI controller, pengatur kecerahan lampu layar laptop |
| **Kenyamanan Mata** | `redshift` | Official | Pengatur temperatur warna / filter cahaya biru (5500K) |
| **Screenshot & Clip** | `maim`, `xclip` | Official | Utilitas screen capture dan integrasi clipboard X11 |
| **Notifikasi Desktop** | `dunst`, `libnotify` | Official | Notification daemon ringan untuk i3wm dan pengirim notifikasi (`notify-send`) |
| **Runtime Wrapper** | `python` | Official | Interpreter untuk mengeksekusi `top-wrapper.py` di i3bar |

---

## 3. Panduan Instalasi Ulang (Fresh Install)

Ketika Anda melakukan instalasi ulang Arch Linux dari nol:

### Langkah 1: Pastikan Paket Git Terpasang
```bash
sudo pacman -S --needed git
```

### Langkah 2: Clone Repositori Ini ke `$HOME`
```bash
git clone <URL_REPO_ANDA> ~/arch-i3wm
cd ~/arch-i3wm
```

### Langkah 3: Jalankan Script Otomasi
Jalankan script sebagai **user biasa** (jangan jalankan `sudo ./install.sh` karena pembuatan paket AUR dilarang dijalankan sebagai root):
```bash
chmod +x install.sh
./install.sh
```

### Apa yang Dilakukan oleh `install.sh` Secara Otomatis?
1. **Validasi User:** Menjamin script dijalankan oleh user biasa yang memiliki hak `sudo`.
2. **Instalasi Paket Resmi:** Menginstal seluruh dependensi Xorg, i3, audio PipeWire, Bluetooth, fonts, dan utilitas pendukung via `pacman -Sy --needed`.
3. **Pemasangan AUR Helper (`yay`):** Jika `yay` belum ada, script otomatis meng-clone dan meng-compile `yay` secara mandiri.
4. **Pemasangan Paket AUR:** Menginstal `i3lock-color` untuk kebutuhan `lock.sh`.
5. **Konfigurasi Hak Akses & Sudoers:**
   * Menambahkan user ke grup `video` dan `input` (agar `brightnessctl` dapat mengatur kecerahan tanpa `sudo`).
   * Mengatur `sudo tailscale set --operator=$USER` dan membuat file `/etc/sudoers.d/10-tailscale` dengan `NOPASSWD` agar toggle VPN bebas password.
6. **Konfigurasi Touchpad Otomatis:** Membuat `/etc/X11/xorg.conf.d/30-touchpad.conf` sehingga Tap-to-Click dan Natural Scrolling langsung aktif.
7. **Konfigurasi Bluetooth Standby:** Menyetel `AutoEnable=false` di `/etc/bluetooth/main.conf` agar Bluetooth tidak boros baterai saat boot.
8. **Aktivasi Layanan Systemd:** Mengaktifkan dan menyalakan `NetworkManager.service`, `bluetooth.service`, dan `tailscaled.service`.
9. **Deploy Seluruh Dotfiles:** Menyalin seluruh file konfigurasi (`.xinitrc`, `.Xresources`, `.zshrc`, `.config/i3/*`, `.config/i3status/*`) ke direktori `$HOME` dengan mekanisme auto-backup jika file lama sudah ada.
10. **Izin Eksekusi Skrip:** Otomatis memberikan `chmod +x` pada seluruh skrip helper (`lock.sh`, `toggle-bluetooth.sh`, `toggle-tailscale.sh`, `toggle-redshift.sh`, `top-wrapper.py`, `wrapper.sh`).
11. **Deteksi Sensor Suhu CPU Dinamis:** Script otomatis memindai jenis prosesor (Intel `x86_pkg_temp`/`coretemp`, AMD `k10temp`, atau ACPI zone) untuk mendeteksi `thermal_zone` yang tepat dan mengonfigurasi `bottom.conf`. Selain itu, `wrapper.sh` juga melakukan deteksi dinamis setiap kali i3bar dijalankan.
12. **Deploy Wallpaper Default:** Otomatis menyalin `wallpaper.jpg` bawaan repositori ke `~/Pictures/wallpaper.jpg` (lengkap dengan pembuatan direktori `~/Pictures`).
13. **Konfigurasi Shell Default:** Mengubah default shell login user ke `/usr/bin/zsh`.
14. **Clone Konfigurasi Neovim:** Otomatis meng-clone repositori konfigurasi Neovim pribadi Anda (`https://github.com/alchemyid/nvim.git`) langsung ke `~/.config/nvim`.

### Langkah 4: Masuk ke Desktop
Setelah instalasi selesai:
```bash
startx
```

---

## 4. Daftar Pintasan Tombol (Keybindings Cheatsheet)

> **Catatan:** Tombol **`Mod`** mengacu pada tombol **Super / Windows** pada keyboard Anda.

| Kombinasi Tombol | Aksi | Keterangan |
| :--- | :--- | :--- |
| **`Mod + Enter`** | Buka Terminal | Membuka terminal Xterm (Gruvbox + Nerd Font 9) |
| **`Mod + d`** | Launcher Aplikasi | Membuka menu pencarian aplikasi (`dmenu`) |
| **`Mod + Shift + q`** | Tutup Jendela | Menutup jendela aplikasi yang sedang aktif (*kill window*) |
| **`Mod + f`** | Toggle Fullscreen | Memperbesar jendela ke ukuran layar penuh |
| **`Mod + Shift + Space`** | Toggle Floating | Mengubah jendela antara mode Tiling (ubin) atau Floating (melayang) |
| **`Mod + h`** | Split Horizontal | Membagi kontainer jendela secara horizontal |
| **`Mod + v`** | Split Vertical | Membagi kontainer jendela secara vertikal |
| **`Mod + j / k / l / ;`** | Pindah Fokus | Berpindah fokus antar jendela (kiri, bawah, atas, kanan) |
| **`Mod + Shift + j / k / l / ;`** | Geser Jendela | Memindahkan posisi jendela aktif |
| **`Mod + 1 s/d 0`** | Pindah Workspace | Beralih ke Workspace 1 sampai 10 |
| **`Mod + Shift + 1 s/d 0`** | Pindah ke Workspace | Memindahkan jendela aktif ke Workspace tertentu |
| **`Mod + r`** | Resize Mode | Mode ubah ukuran jendela (gunakan tombol panah atau `j/k/l/;`) |
| **`Mod + Shift + x`** | **Kunci Layar (Lock)** | Mengunci layar dengan efek blur; ketik password login untuk unlock |
| **`PrintScreen`** | Screenshot Area | Menyeleksi area layar dan menyimpannya langsung ke clipboard |
| **`Mod + PrintScreen`** | Screenshot Penuh | Menangkap seluruh tampilan layar ke clipboard |
| **`Mod + b`** | **Toggle Bluetooth** | Menyalakan/mematikan Bluetooth (auto-connect ke headset WZ-BT5.0) |
| **`Mod + t`** | **Toggle Tailscale** | Menghubungkan/memutuskan koneksi VPN Tailscale ke homelab |
| **`Mod + n`** | **Toggle Night Light** | Mode dimm hangat 5500K (`redshift`) untuk meredakan mata lelah |
| **`Fn + F3 / F4`** | Kecerahan Layar | Menaikkan/menurunkan kecerahan monitor (`brightnessctl`) |
| **`Fn + Volume Keys`** | Pengatur Suara | Menaikkan, menurunkan, dan mematikan suara speaker / mic |
| **`Mod + Shift + r`** | **Reload i3wm** | Me-restart sesi i3 secara in-place tanpa menutup aplikasi yang terbuka |
| **`Mod + Shift + e`** | **Logout / Exit** | Menampilkan bilah konfirmasi untuk keluar dari sesi X11 |

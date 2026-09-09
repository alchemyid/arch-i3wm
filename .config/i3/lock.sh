#!/bin/bash

IMG=/tmp/i3lock.png

# 1. Ambil screenshot dan manipulasi piksel (efek blur ringan)
scrot $IMG
convert $IMG -scale 10% -scale 1000% $IMG

# 2. Palet Warna (Diambil dari hex i3status Anda + transparansi)
# Format i3lock-color adalah RRGGBBAA (AA adalah transparansi)
MERAH="fb4934ff"    # color_bad
KUNING="fabd2fff"   # color_degraded
HIJAU="b8bb26ff"    # color_good
KOSONG="00000000"   # Transparan

# 3. Eksekusi i3lock-color dengan indikator visual
i3lock -i $IMG \
  --insidever-color=$KOSONG   \
  --ringver-color=$KUNING     \
  \
  --insidewrong-color=$KOSONG \
  --ringwrong-color=$MERAH    \
  \
  --inside-color=$KOSONG      \
  --ring-color=$HIJAU         \
  --line-color=$KOSONG        \
  --separator-color=$HIJAU    \
  \
  --verif-color=$KUNING       \
  --wrong-color=$MERAH        \
  --time-color=$HIJAU         \
  --date-color=$HIJAU         \
  --layout-color=$HIJAU       \
  --keyhl-color=$KUNING       \
  --bshl-color=$MERAH         \
  \
  --clock               \
  --indicator           \
  --time-str="%H:%M:%S" \
  --date-str="%Y-%m-%d" \
  --radius=120          \
  --ring-width=5

# 4. Hapus gambar sementara
rm $IMG

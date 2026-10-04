#!/system/bin/sh
# Action: buka WebUI di WebUI X. Jika halaman TIDAK berhasil termuat dalam 10 detik,
# otomatis pindah ke browser (server lokal). Paksa browser: buat file kosong "Dail_browser" di penyimpanan internal.
MODDIR=${0%/*}; ID=dail_modul; D=/data/adb/dail; PORT=8765; W=/data/adb/modules/$ID/webroot
BB=/data/adb/magisk/busybox; [ -x $BB ] || BB=busybox
mkdir -p $D
L=$(getprop persist.sys.locale); [ -z "$L" ] && L=$(getprop ro.product.locale); [ -z "$L" ] && L=$(getprop persist.sys.language)
case "$L" in id*|in*) IDL=1;; *) IDL=0;; esac
m(){ if [ "$IDL" = 1 ]; then echo "$1"; else echo "$2"; fi; }

if [ ! -f $W/index.html ]; then
  m "! WebUI belum aktif. Reboot dulu setelah flash, lalu tekan Action lagi." "! WebUI is not active yet. Reboot after flashing, then press Action again."; exit 1
fi

# true jika halaman WebUI berhasil memanggil dail.sh (tanda sudah termuat)
wait_ui(){ i=0; while [ $i -lt 10 ]; do [ -f $D/ui_seen ] && return 0; sleep 1; i=$((i+1)); done; return 1; }
try_app(){ rm -f $D/ui_seen; m "- Membuka WebUI di $1..." "- Opening WebUI in $1..."; shift; am start "$@" >/dev/null 2>&1 && wait_ui; }

browser(){
  $BB --list 2>/dev/null | grep -qx httpd || { m "! Busybox Magisk tidak punya httpd." "! Magisk busybox has no httpd."; m "  Pasang/Update WebUI X rilis stabil lalu coba lagi." "  Install/update a stable WebUI X release and try again."; exit 1; }
  [ -f $D/httpd.pid ] && kill $(cat $D/httpd.pid) 2>/dev/null
  cat /proc/sys/kernel/random/uuid | tr -d '-' > $D/token; date +%s > $D/last
  chmod 755 $W/cgi-bin/api.sh
  nohup $BB httpd -f -p 127.0.0.1:$PORT -h $W >/dev/null 2>&1 &
  echo $! > $D/httpd.pid
  ( while sleep 60; do [ $(( $(date +%s) - $(cat $D/last 2>/dev/null || echo 0) )) -gt 600 ] && break; done
    kill $(cat $D/httpd.pid) 2>/dev/null ) >/dev/null 2>&1 &
  URL="http://127.0.0.1:$PORT/?t=$(cat $D/token)"
  m "- Membuka di browser (berhenti otomatis setelah 10 menit)" "- Opening in browser (auto-stops after 10 minutes)"; echo "$URL"
  am start --user 0 -a android.intent.action.VIEW -d "$URL" >/dev/null 2>&1 || m "Buka URL di atas secara manual." "Open the URL above manually."
  exit 0
}

[ -f /sdcard/Dail_browser ] && browser

for P in com.dergoogler.mmrl.wx com.dergoogler.mmrl.wx.alpha; do
  pm path $P >/dev/null 2>&1 || continue
  try_app $P -n "$P/com.dergoogler.mmrl.wx.ui.activity.webui.WebUIActivity" -e MOD_ID "$ID" && { m "- WebUI termuat" "- WebUI loaded"; exit 0; }
  m "! $P gagal memuat WebUI" "! $P failed to load WebUI"
done
if pm path io.github.a13e300.ksuwebui >/dev/null 2>&1; then
  try_app KSUWebUIStandalone -n "io.github.a13e300.ksuwebui/.WebUIActivity" -e id "$ID" && { m "- WebUI termuat" "- WebUI loaded"; exit 0; }
  m "! KSUWebUIStandalone gagal memuat WebUI" "! KSUWebUIStandalone failed to load WebUI"
fi
m "- Beralih ke browser..." "- Switching to browser..."; browser

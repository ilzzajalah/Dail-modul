SKIPMOUNT=false
L=$(getprop persist.sys.locale); [ -z "$L" ] && L=$(getprop ro.product.locale); [ -z "$L" ] && L=$(getprop persist.sys.language)
case "$L" in id*|in*) IDL=1;; *) IDL=0;; esac
m(){ if [ "$IDL" = 1 ]; then echo "$1"; else echo "$2"; fi; }
ui_print "- Dail Modul v1.7"
[ "$API" -lt 29 ] && abort "$(m '! Butuh Android 10 (API 29) ke atas' '! Requires Android 10 (API 29) or newer')"
ui_print "- Android API $API OK"
ui_print "$(m '- Mode systemless, tanpa edit partisi' '- Systemless, no partition edits')"
chmod 0755 $MODPATH/webroot/cgi-bin/api.sh
set_perm_recursive $MODPATH 0 0 0755 0644
for f in dail.sh post-fs-data.sh service.sh action.sh uninstall.sh webroot/cgi-bin/api.sh; do set_perm $MODPATH/$f 0 0 0755; done
ui_print "$(m '- Reboot dulu, lalu tekan tombol Action untuk membuka WebUI' '- Reboot first, then press Action to open the WebUI')"
ui_print "$(m '- WebUI: WebUI X (Magisk) atau bawaan KernelSU/APatch' '- WebUI: WebUI X (Magisk) or built-in KernelSU/APatch')"

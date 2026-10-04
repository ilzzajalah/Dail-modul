#!/system/bin/sh
# Dail Modul core v1.1 - runtime only, reversible
D=/data/adb/dail; CFG=$D/config.conf; LOG=$D/dail.log; MOD=/data/adb/modules/dail_modul
BB=/data/adb/magisk/busybox; [ -x $BB ] || BB=busybox
mkdir -p $D
[ -f $CFG ] || printf 'net=1\ndns=off\nsaver=0\nanim=0\nbsaver=0\n' > $CFG
touch $D/boost.list $D/save.list $D/restricted.list
for a in "$@"; do case "$a" in *[!A-Za-z0-9_.,-]*) echo "ERR arg"; exit 1;; esac; done

get(){ grep "^$1=" $CFG | tail -n1 | cut -d= -f2; }
setc(){ grep -v "^$1=" $CFG > $CFG.t; echo "$1=$2" >> $CFG.t; mv $CFG.t $CFG; }
log(){ echo "$(date '+%F %T') $*" >> $LOG; [ "$(wc -c < $LOG)" -gt 65536 ] && { tail -n 100 $LOG > $LOG.t; mv $LOG.t $LOG; }; }
installed(){ pm path "$1" >/dev/null 2>&1; }
wsave(){ n=$(echo "$1" | tr '/' '_'); [ -w "$1" ] || return 0
  [ -f "$D/o$n" ] || cat "$1" > "$D/o$n"; echo "$2" > "$1" 2>/dev/null; }

apply_net(){ P=/proc/sys/net/ipv4
  if [ "$(get net)" = 1 ]; then
    wsave $P/tcp_fastopen 3; wsave $P/tcp_slow_start_after_idle 0; wsave $P/tcp_mtu_probing 1
    grep -qw bbr $P/tcp_available_congestion_control 2>/dev/null && wsave $P/tcp_congestion_control bbr
    log "net tuned"
  else restore_net; fi; }
restore_net(){ for f in $D/o_proc_sys_net_*; do [ -f "$f" ] || continue
  p=$(basename $f | sed 's/^o//;s/_/\//g'); [ -w "$p" ] && cat $f > $p; rm -f $f; done; }

apply_dns(){
  [ -f $D/odns ] || { settings get global private_dns_mode > $D/odns; settings get global private_dns_specifier > $D/odnss; }
  case "$(get dns)" in cf) H=one.one.one.one;; google) H=dns.google;; adguard) H=dns.adguard-dns.com;; *) restore_dns; return;; esac
  settings put global private_dns_specifier $H; settings put global private_dns_mode hostname; log "dns $H"; }
restore_dns(){ [ -f $D/odns ] || return 0; m=$(cat $D/odns)
  if [ "$m" = null ] || [ -z "$m" ]; then settings delete global private_dns_mode >/dev/null 2>&1; else settings put global private_dns_mode $m; fi
  s=$(cat $D/odnss); [ "$s" != null ] && [ -n "$s" ] && settings put global private_dns_specifier $s; rm -f $D/odns $D/odnss; }

uid_of(){ cmd package list packages -U $1 2>/dev/null | sed -n "s/^package:$1 .*uid:\([0-9]*\).*/\1/p" | head -n1; }
apply_saver(){
  if [ "$(get saver)" = 1 ]; then
    cmd netpolicy set restrict-background true
    for p in $(cat $D/boost.list); do u=$(uid_of $p); [ -n "$u" ] && cmd netpolicy add restrict-background-whitelist $u; done
    log "data saver on"
  else cmd netpolicy set restrict-background false; fi; }

apply_boost(){ for p in $(cat $D/boost.list); do installed $p || continue
  am set-standby-bucket $p active </dev/null 2>/dev/null
  cmd deviceidle whitelist +$p </dev/null >/dev/null 2>&1
  cmd appops set $p RUN_ANY_IN_BACKGROUND allow </dev/null 2>/dev/null; done; log "boost apps: $(wc -l < $D/boost.list)"; }

unrestrict(){ for p in $(cat $D/restricted.list); do cmd appops set $p RUN_ANY_IN_BACKGROUND default </dev/null 2>/dev/null
  am set-standby-bucket $p working_set </dev/null 2>/dev/null; done; : > $D/restricted.list; }
apply_bsaver(){
  if [ "$(get bsaver)" = 1 ]; then
    settings put global low_power 1; touch $D/lp_set
    for p in $(cat $D/save.list); do grep -qx "$p" $D/boost.list && continue; installed $p || continue
      cmd appops set $p RUN_ANY_IN_BACKGROUND ignore </dev/null 2>/dev/null
      am set-standby-bucket $p restricted </dev/null 2>/dev/null; echo $p >> $D/restricted.list; done
    sort -u $D/restricted.list -o $D/restricted.list; log "battery saver on"
  else [ -f $D/lp_set ] && { settings put global low_power 0; rm -f $D/lp_set; }; unrestrict; fi; }
apply_anim(){ v=1.0; [ "$(get anim)" = 1 ] && v=0.5
  for k in window_animation_scale transition_animation_scale animator_duration_scale; do settings put global $k $v; done; }

detect(){ inst=$(pm list packages 2>/dev/null | sed 's/^package://')
  while IFS='|' read -r p n; do echo "$inst" | grep -qx "$p" && echo "$p|$n"; done < $MOD/known.txt; }
apps(){ pm list packages -3 2>/dev/null | sed 's/^package://' | sort; }
setlist(){ case "$1" in boost|save) ;; *) return 1;; esac
  if [ "$2" = "-" ] || [ -z "$2" ]; then : > $D/$1.list; else echo "$2" | tr ',' '\n' | grep -v '^$' | sort -u > $D/$1.list; fi
  # satu aplikasi tidak boleh di dua daftar
  o=boost; [ "$1" = boost ] && o=save; grep -vxFf $D/$1.list $D/$o.list > $D/$o.t 2>/dev/null; mv $D/$o.t $D/$o.list; echo OK; }

now(){ $BB date +%s%N | cut -c1-13; }
pingt(){ o=$(ping -c 4 -W 2 $1 2>/dev/null)
  l=$(echo "$o" | sed -n 's/.* \([0-9]*\)% packet loss.*/\1/p')
  r=$(echo "$o" | sed -n 's/.*= *\([0-9.]*\)\/\([0-9.]*\)\/\([0-9.]*\)\/\([0-9.]*\).*/\2 \4/p')
  echo "$2_ms=${r%% *}"; echo "$2_jit=${r##* }"; echo "$2_loss=${l:-100}"; }
nettest(){ pingt 1.1.1.1 cf; pingt 8.8.8.8 gg
  s=$(now); ping -c 1 -W 3 google.com >/dev/null 2>&1 && echo "dns_ms=$(( $(now) - s ))" || echo "dns_ms="; }
speedtest(){ for u in http://speedtest.tele2.net/10MB.zip http://cachefly.cachefly.net/10mb.test; do
  s=$(now); b=$($BB wget -q -T 6 -O - $u 2>/dev/null | head -c 5000000 | wc -c); e=$(( $(now) - s ))
  [ "$b" -gt 100000 ] && [ "$e" -gt 0 ] && { echo "mbps=$(( b * 8 / e / 1000 )).$(( (b * 8 / e / 100) % 10 ))"; return; }; done; echo "mbps="; }

optimize(){ ( for p in $(cat $D/boost.list); do installed $p && cmd package compile -m speed-profile -f $p; done; log "dexopt selesai" ) >/dev/null 2>&1 &
  echo "Optimasi berjalan di background"; }
clear_cache(){ for p in $(cat $D/boost.list); do rm -rf /data/data/$p/cache/* /data/data/$p/code_cache/* 2>/dev/null; done; echo "Cache app boost dibersihkan"; }
stopserver(){ echo "Server dihentikan"; kill $(cat $D/httpd.pid 2>/dev/null) 2>/dev/null; }

memav(){ grep MemAvailable /proc/meminfo | tr -s ' ' | cut -d' ' -f2; }
info(){ dumpsys battery 2>/dev/null | sed -n 's/^ *level: *\([0-9]*\).*/batt=\1/p;s/^ *temperature: *\([0-9]*\).*/temp=\1/p'
  echo "ram_free=$(( $(memav) / 1024 ))"; echo "ram_total=$(( $(grep MemTotal /proc/meminfo | tr -s ' ' | cut -d' ' -f2) / 1024 ))"
  set -- $(df -k /data 2>/dev/null | tail -n 1); echo "disk_free=$(( ${4:-0} / 1024 ))"; echo "disk_total=$(( ${2:-0} / 1024 ))"; }
ramclean(){ b=$(memav); am kill-all </dev/null 2>/dev/null; sync; echo 3 > /proc/sys/vm/drop_caches 2>/dev/null; sleep 1
  a=$(memav); log "ram clean +$(( (a - b) / 1024 ))MB"; echo "RAM dibersihkan: +$(( (a - b) / 1024 )) MB"; }
trim(){ ( $BB fstrim -v /data || sm fstrim ) >/dev/null 2>&1 & echo "TRIM storage berjalan di background"; }

status(){
  echo "api=$(getprop ro.build.version.sdk)"; echo "cc=$(cat /proc/sys/net/ipv4/tcp_congestion_control 2>/dev/null)"
  echo "tfo=$(cat /proc/sys/net/ipv4/tcp_fastopen 2>/dev/null)"; echo "dnsmode=$(settings get global private_dns_mode)"
  echo "lowpower=$(settings get global low_power)"; echo "bootcount=$(cat $D/bootcount 2>/dev/null)"
  for k in net dns saver anim bsaver; do echo "cfg_$k=$(get $k)"; done; }
lists(){ echo "boost=$(tr '\n' ',' < $D/boost.list)"; echo "save=$(tr '\n' ',' < $D/save.list)"; }

case "$1" in
  apply) apply_net; apply_dns; apply_boost; apply_saver; apply_bsaver; apply_anim; echo "OK";;
  set) setc "$2" "$3"; echo "OK";;
  status) date +%s > $D/ui_seen; status;; detect) detect;; apps) apps;; lists) lists;;
  setlist) setlist "$2" "$3";; nettest) nettest;; speedtest) speedtest;;
  info) info;; ram) ramclean;; trim) trim;;
  optimize) optimize;; cache) clear_cache;; stop) stopserver;;
  restore) restore_net; restore_dns; unrestrict; [ -f $D/lp_set ] && { settings put global low_power 0; rm -f $D/lp_set; }
    cmd netpolicy set restrict-background false
    for k in window_animation_scale transition_animation_scale animator_duration_scale; do settings put global $k 1.0; done; echo "OK";;
  log) tail -n 30 $LOG 2>/dev/null;;
  *) echo "usage: dail.sh info|ram|trim|apply|set|status|detect|apps|lists|setlist|nettest|speedtest|optimize|cache|stop|restore|log";;
esac

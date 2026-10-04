#!/system/bin/sh
# Boot guard: hanya counter ringan, tanpa tweak apapun di fase ini
MODDIR=${0%/*}
D=/data/adb/dail; mkdir -p $D
C=$(cat $D/bootcount 2>/dev/null); [ -z "$C" ] && C=0
C=$((C+1)); echo $C > $D/bootcount
if [ "$C" -ge 3 ]; then
  touch $MODDIR/disable
  echo 0 > $D/bootcount
  echo "$(date) boot gagal 3x, module auto-disable" >> $D/dail.log
fi

#!/system/bin/sh
MODDIR=${0%/*}
(
  while [ "$(getprop sys.boot_completed)" != "1" ]; do sleep 5; done
  sleep 20
  echo 0 > /data/adb/dail/bootcount
  sh $MODDIR/dail.sh apply >/dev/null 2>&1
) &

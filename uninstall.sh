#!/system/bin/sh
MODDIR="${0%/*}"
[ -x "$MODDIR/bin/xyvonix_cli.sh" ] && "$MODDIR/bin/xyvonix_cli.sh" reset >/dev/null 2>&1
rm -rf "$MODDIR/data" 2>/dev/null

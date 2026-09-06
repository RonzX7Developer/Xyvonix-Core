#!/system/bin/sh
MODDIR="${0%/*}"
"$MODDIR/bin/xyvonix_cli.sh" optimize
printf '%s\n' "Xyvonix Core v3.0 optimization requested."

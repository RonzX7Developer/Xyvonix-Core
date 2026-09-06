#!/system/bin/sh
MODDIR="${0%/*}"
CLI="$MODDIR/bin/xyvonix_cli.sh"

mkdir -p "$MODDIR/data"
[ -f "$MODDIR/data/profile" ] || printf '%s\n' balanced > "$MODDIR/data/profile"
[ -f "$MODDIR/data/dns_mode" ] || printf '%s\n' auto > "$MODDIR/data/dns_mode"
[ -f "$MODDIR/data/auto_game" ] || printf '%s\n' 0 > "$MODDIR/data/auto_game"
[ -f "$MODDIR/data/games.list" ] || : > "$MODDIR/data/games.list"
[ -f "$MODDIR/data/ignore.list" ] || : > "$MODDIR/data/ignore.list"

until [ "$(getprop sys.boot_completed 2>/dev/null)" = "1" ]; do sleep 2; done
sleep 3

p="$(cat "$MODDIR/data/profile" 2>/dev/null)"
case "$p" in performance|balanced|battery) "$CLI" profile "$p" >/dev/null 2>&1;; *) "$CLI" profile balanced >/dev/null 2>&1;; esac

[ "$(cat "$MODDIR/data/render" 2>/dev/null)" = "1" ] && "$CLI" render on >/dev/null 2>&1
[ "$(cat "$MODDIR/data/blur" 2>/dev/null)" = "1" ] && "$CLI" blur on >/dev/null 2>&1
[ "$(cat "$MODDIR/data/refresh" 2>/dev/null)" = "1" ] && "$CLI" refresh on >/dev/null 2>&1
[ "$(cat "$MODDIR/data/network" 2>/dev/null)" = "1" ] && "$CLI" network on >/dev/null 2>&1
[ "$(cat "$MODDIR/data/wifi_latency" 2>/dev/null)" = "1" ] && "$CLI" wifi-latency on >/dev/null 2>&1

mode="$(cat "$MODDIR/data/dns_mode" 2>/dev/null)"
host="$(cat "$MODDIR/data/dns_provider" 2>/dev/null)"
case "$mode" in
  off) "$CLI" dns off >/dev/null 2>&1;;
  auto) "$CLI" dns auto >/dev/null 2>&1;;
  hostname) [ -n "$host" ] && "$CLI" dns hostname "$host" >/dev/null 2>&1;;
esac

# Re-apply the Doze whitelist for tracked games after reboot (best-effort, ignored if unsupported)
if [ -f "$MODDIR/data/games.list" ]; then
  while IFS= read -r pkg; do
    [ -n "$pkg" ] && dumpsys deviceidle whitelist "+$pkg" >/dev/null 2>&1
  done < "$MODDIR/data/games.list"
fi
exit 0

#!/system/bin/sh
# Xyvonix Core v3.0 - defensive install script for AxManager (non-root)

# Fallback jika AxManager tidak menyediakan ui_print di context customize.sh
type ui_print >/dev/null 2>&1 || ui_print() { echo "$1"; }

# Fallback jika $MODPATH tidak di-export oleh installer (pakai lokasi script ini)
if [ -z "$MODPATH" ]; then
    MODPATH="$(cd "$(dirname "$0")" && pwd)"
fi

ui_print "=============================================="
ui_print "              XYVONIX CORE v3.0"
ui_print "              RonzX7 Developer"
ui_print "=============================================="
ui_print "- AxManager plugin / non-root target"
ui_print "- Performance, network, DNS, gaming and diagnostics"
ui_print "- Background app manager and game auto-detection"
ui_print "- Thermal protection and Android security preserved"

mkdir -p "$MODPATH/data/backup" "$MODPATH/data/logs" 2>/dev/null
chmod 0755 "$MODPATH/action.sh" "$MODPATH/service.sh" "$MODPATH/uninstall.sh" 2>/dev/null
chmod 0755 "$MODPATH/bin/xyvonix_cli.sh" "$MODPATH/system/bin/xyvonix" 2>/dev/null
chmod 0644 "$MODPATH/module.prop" "$MODPATH/banner.png" 2>/dev/null
find "$MODPATH/webroot" -type f -exec chmod 0644 {} \; 2>/dev/null

[ -f "$MODPATH/data/profile" ] || printf '%s\n' balanced > "$MODPATH/data/profile" 2>/dev/null
[ -f "$MODPATH/data/dns_mode" ] || printf '%s\n' auto > "$MODPATH/data/dns_mode" 2>/dev/null
[ -f "$MODPATH/data/render" ] || printf '%s\n' 0 > "$MODPATH/data/render" 2>/dev/null
[ -f "$MODPATH/data/blur" ] || printf '%s\n' 0 > "$MODPATH/data/blur" 2>/dev/null
[ -f "$MODPATH/data/refresh" ] || printf '%s\n' 0 > "$MODPATH/data/refresh" 2>/dev/null
[ -f "$MODPATH/data/network" ] || printf '%s\n' 0 > "$MODPATH/data/network" 2>/dev/null
[ -f "$MODPATH/data/wifi_latency" ] || printf '%s\n' 0 > "$MODPATH/data/wifi_latency" 2>/dev/null
[ -f "$MODPATH/data/auto_game" ] || printf '%s\n' 0 > "$MODPATH/data/auto_game" 2>/dev/null
[ -f "$MODPATH/data/games.list" ] || : > "$MODPATH/data/games.list" 2>/dev/null
[ -f "$MODPATH/data/ignore.list" ] || : > "$MODPATH/data/ignore.list" 2>/dev/null

ui_print "- Device: $(getprop ro.product.model 2>/dev/null)"
ui_print "- HyperOS: $(getprop ro.miui.ui.version.name 2>/dev/null)"
ui_print "- Android: $(getprop ro.build.version.release 2>/dev/null) / API $(getprop ro.build.version.sdk 2>/dev/null)"
ui_print "- Installation prepared for AxManager"
exit 0

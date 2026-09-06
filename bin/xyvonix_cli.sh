#!/system/bin/sh
# Xyvonix Core v3.0 — AxManager non-root runtime
MODDIR="${0%/*}"
ROOT="${MODDIR%/bin}"
STATE="$ROOT/data"
BACKUP="$STATE/backup"
mkdir -p "$STATE" "$BACKUP"

out(){ printf '%s\n' "$*"; }

# The AxManager WebUI bridge tokenizes commands on whitespace only and does
# NOT understand shell quoting, so arguments must never rely on quotes to
# survive the trip from app.js. strip_quotes() is defense-in-depth in case a
# stray leading/trailing quote character still arrives from the bridge.
strip_quotes(){ printf '%s' "$1" | sed 's/^"//; s/"$//'; }
valid_pkg(){ printf '%s' "$1" | grep -Eq '^[A-Za-z0-9_][A-Za-z0-9_.]*$'; }
valid_host(){ printf '%s' "$1" | grep -Eq '^[A-Za-z0-9][A-Za-z0-9._-]*$'; }
sdk(){ getprop ro.build.version.sdk 2>/dev/null; }

json_escape(){
  printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g; s/\t/\\t/g; s/\r/\\r/g; s/\n/\\n/g'
}

ram_mb(){ awk '/^MemTotal:/{printf "%d",$2/1024; exit}' /proc/meminfo 2>/dev/null; }

max_refresh(){
  dumpsys display 2>/dev/null |
    grep -Eo 'fps=[0-9]+([.][0-9]+)?' |
    cut -d= -f2 | sort -n | tail -1
}

cpu_governor(){
  for f in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
    [ -f "$f" ] && { cat "$f" 2>/dev/null; return; }
  done
  out "unavailable"
}

gpu_path(){
  for d in /sys/class/devfreq/* /sys/class/kgsl/kgsl-3d0/devfreq; do
    [ -f "$d/governor" ] || continue
    n="$(cat "$d/name" 2>/dev/null)"
    case "$d $n" in *gpu*|*GPU*|*kgsl*) out "$d"; return;; esac
  done
}

choose_governor(){
  wanted="$1"; avail=""
  for f in /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_governors /sys/devices/system/cpu/cpu4/cpufreq/scaling_available_governors; do
    [ -f "$f" ] && { avail="$(cat "$f" 2>/dev/null)"; break; }
  done
  case " $avail " in *" $wanted "*) out "$wanted"; return;; esac
  case "$wanted" in
    performance) for x in schedutil interactive ondemand powersave; do case " $avail " in *" $x "*) out "$x"; return;; esac; done;;
    powersave) for x in schedutil ondemand conservative performance; do case " $avail " in *" $x "*) out "$x"; return;; esac; done;;
    schedutil) for x in ondemand interactive powersave performance; do case " $avail " in *" $x "*) out "$x"; return;; esac; done;;
  esac
  out ""
}

backup_settings(){
  [ -f "$BACKUP/settings" ] || {
    {
      printf 'window_animation_scale|%s\n' "$(settings get global window_animation_scale 2>/dev/null)"
      printf 'transition_animation_scale|%s\n' "$(settings get global transition_animation_scale 2>/dev/null)"
      printf 'animator_duration_scale|%s\n' "$(settings get global animator_duration_scale 2>/dev/null)"
      printf 'peak_refresh_rate|%s\n' "$(settings get global peak_refresh_rate 2>/dev/null)"
      printf 'min_refresh_rate|%s\n' "$(settings get global min_refresh_rate 2>/dev/null)"
      printf 'low_power|%s\n' "$(settings get global low_power 2>/dev/null)"
      printf 'wifi_suspend_optimizations_enabled|%s\n' "$(settings get global wifi_suspend_optimizations_enabled 2>/dev/null)"
      printf 'wifi_watchdog_on|%s\n' "$(settings get global wifi_watchdog_on 2>/dev/null)"
      printf 'netstats_poll_interval|%s\n' "$(settings get global netstats_poll_interval 2>/dev/null)"
    } > "$BACKUP/settings"
  }
  [ -f "$BACKUP/cpu_governors" ] || {
    : > "$BACKUP/cpu_governors"
    for f in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
      [ -f "$f" ] && printf '%s|%s\n' "$f" "$(cat "$f" 2>/dev/null)" >> "$BACKUP/cpu_governors"
    done
  }
  [ -f "$BACKUP/gpu_governor" ] || {
    g="$(gpu_path)"
    [ -n "$g" ] && printf '%s|%s\n' "$g" "$(cat "$g/governor" 2>/dev/null)" > "$BACKUP/gpu_governor"
  }
}

apply_cpu(){
  gov="$(choose_governor "$1")"; [ -n "$gov" ] || return 0
  for f in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
    [ -w "$f" ] && printf '%s\n' "$gov" > "$f" 2>/dev/null
  done
}

apply_gpu(){
  p="$1"; d="$(gpu_path)"; [ -n "$d" ] || return 0
  avail="$(cat "$d/available_governors" 2>/dev/null)"
  case "$p" in performance) wanted=performance;; battery) wanted=powersave;; *) wanted=simple_ondemand;; esac
  case " $avail " in *" $wanted "*) printf '%s\n' "$wanted" > "$d/governor" 2>/dev/null;; esac
}

apply_profile(){
  p="$1"
  case "$p" in performance|balanced|battery) ;; *) return 2;; esac
  backup_settings
  case "$p" in
    performance)
      apply_cpu performance; apply_gpu performance
      settings put global low_power 0 2>/dev/null
      settings put global window_animation_scale 0.5 2>/dev/null
      settings put global transition_animation_scale 0.5 2>/dev/null
      settings put global animator_duration_scale 0.5 2>/dev/null
      ;;
    balanced)
      apply_cpu schedutil; apply_gpu balanced
      settings put global low_power 0 2>/dev/null
      settings put global window_animation_scale 1.0 2>/dev/null
      settings put global transition_animation_scale 1.0 2>/dev/null
      settings put global animator_duration_scale 1.0 2>/dev/null
      ;;
    battery)
      apply_cpu powersave; apply_gpu battery
      settings put global low_power 1 2>/dev/null
      settings put global window_animation_scale 1.0 2>/dev/null
      settings put global transition_animation_scale 1.0 2>/dev/null
      settings put global animator_duration_scale 1.0 2>/dev/null
      ;;
  esac
  printf '%s\n' "$p" > "$STATE/profile"
  out "profile=$p"
}

apply_render(){
  mode="$1"
  case "$mode" in
    on)
      setprop debug.sf.multithreaded_present 1 2>/dev/null
      setprop debug.sf.use_frame_rate_priority 1 2>/dev/null
      setprop debug.hwui.initialize_gl_always true 2>/dev/null
      setprop debug.hwui.early_preload_gl_context true 2>/dev/null
      setprop debug.hwui.skip_eglmanager_telemetry true 2>/dev/null
      setprop debug.hwui.trace_gpu_resources false 2>/dev/null
      setprop debug.hwui.skia_tracing_enabled false 2>/dev/null
      setprop debug.renderengine.skia_tracing_enabled false 2>/dev/null
      setprop debug.renderengine.skia_use_perfetto_track_events false 2>/dev/null
      setprop vendor.perf.gestureflingboost.enable true 2>/dev/null
      setprop vendor.perf.workloadclassifier.enable true 2>/dev/null
      printf 1 > "$STATE/render" ;;
    off)
      for k in debug.sf.multithreaded_present debug.sf.use_frame_rate_priority debug.hwui.initialize_gl_always debug.hwui.early_preload_gl_context debug.hwui.skip_eglmanager_telemetry vendor.perf.gestureflingboost.enable vendor.perf.workloadclassifier.enable; do
        setprop "$k" "" 2>/dev/null
      done
      printf 0 > "$STATE/render" ;;
    *) return 2;;
  esac
}

apply_blur(){
  mode="$1"
  case "$mode" in
    on) setprop persist.sys.background_blur_supported true 2>/dev/null; printf 1 > "$STATE/blur";;
    off) setprop persist.sys.background_blur_supported false 2>/dev/null; printf 0 > "$STATE/blur";;
    *) return 2;;
  esac
}

apply_refresh(){
  mode="$1"
  case "$mode" in
    on)
      hz="$(max_refresh)"
      case "$hz" in ''|*[!0-9.]*|0) return 2;; esac
      backup_settings
      settings put global peak_refresh_rate "$hz" 2>/dev/null
      settings put global min_refresh_rate "$hz" 2>/dev/null
      printf '%s\n' "$hz" > "$STATE/refresh" ;;
    off)
      if [ -f "$BACKUP/settings" ]; then
        while IFS='|' read -r k v; do
          case "$k" in peak_refresh_rate|min_refresh_rate) [ "$v" != "null" ] && settings put global "$k" "$v" 2>/dev/null;; esac
        done < "$BACKUP/settings"
      fi
      printf 0 > "$STATE/refresh" ;;
    *) return 2;;
  esac
}

apply_wifi_latency(){
  mode="$1"
  case "$mode" in
    on)
      command -v cmd >/dev/null 2>&1 || return 2
      cmd wifi force-low-latency-mode enabled >/dev/null 2>&1 || return 2
      printf 1 > "$STATE/wifi_latency" ;;
    off)
      cmd wifi force-low-latency-mode disabled >/dev/null 2>&1 || true
      printf 0 > "$STATE/wifi_latency" ;;
    *) return 2;;
  esac
}

apply_network(){
  mode="$1"; backup_settings
  case "$mode" in
    on)
      settings put global wifi_suspend_optimizations_enabled 0 2>/dev/null
      settings put global wifi_watchdog_on 1 2>/dev/null
      settings put global netstats_poll_interval 86400000 2>/dev/null
      setprop net.tcp.default_init_rwnd 60 2>/dev/null
      printf 1 > "$STATE/network" ;;
    off)
      if [ -f "$BACKUP/settings" ]; then
        while IFS='|' read -r k v; do
          case "$k" in wifi_suspend_optimizations_enabled|wifi_watchdog_on|netstats_poll_interval)
            [ "$v" != "null" ] && settings put global "$k" "$v" 2>/dev/null;;
          esac
        done < "$BACKUP/settings"
      fi
      setprop net.tcp.default_init_rwnd "" 2>/dev/null
      printf 0 > "$STATE/network" ;;
    *) return 2;;
  esac
}

apply_dns(){
  m="$1"; h="$(strip_quotes "$2")"
  case "$m" in
    off) settings put global private_dns_mode off 2>/dev/null; settings put global private_dns_specifier "" 2>/dev/null;;
    auto) settings put global private_dns_mode opportunistic 2>/dev/null; settings put global private_dns_specifier "" 2>/dev/null;;
    hostname) valid_host "$h" || return 2; settings put global private_dns_mode hostname 2>/dev/null; settings put global private_dns_specifier "$h" 2>/dev/null; printf '%s\n' "$h" > "$STATE/dns_provider";;
    *) return 2;;
  esac
  printf '%s\n' "$m" > "$STATE/dns_mode"
}

apply_memory(){
  cmd device_config put activity_manager use_compaction true >/dev/null 2>&1
  cmd device_config put activity_manager process_start_async true >/dev/null 2>&1
  cmd device_config put activity_manager max_previous_time 60000 >/dev/null 2>&1
  printf 1 > "$STATE/memory"
}

trim(){
  cmd activity trim-caches >/dev/null 2>&1
  pm trim-caches 2147483647 >/dev/null 2>&1
}

storage_trim(){ sm fstrim >/dev/null 2>&1; }

discover_games(){
  f="$STATE/games.list"; : > "$f"
  if [ "$(sdk)" -ge 31 ] 2>/dev/null; then
    dumpsys game 2>/dev/null | grep -Eo 'com\.[A-Za-z0-9._]+' | sort -u >> "$f"
  fi
  pm list packages -3 2>/dev/null | cut -d: -f2 | sort -u >> "$f"
  sort -u "$f" -o "$f"
}
game_add(){
  p="$(strip_quotes "$1")"; valid_pkg "$p" || return 2
  grep -Fxq "$p" "$STATE/games.list" 2>/dev/null || printf '%s\n' "$p" >> "$STATE/games.list"
  dumpsys deviceidle whitelist "+$p" >/dev/null 2>&1
}
game_remove(){
  p="$(strip_quotes "$1")"; valid_pkg "$p" || return 2
  grep -Fvx "$p" "$STATE/games.list" > "$STATE/games.tmp" 2>/dev/null || :
  mv -f "$STATE/games.tmp" "$STATE/games.list"
  dumpsys deviceidle whitelist "-$p" >/dev/null 2>&1
}
game_compile(){
  p="$(strip_quotes "$1")"; m="$(strip_quotes "$2")"
  valid_pkg "$p" || return 2
  case "$m" in speed|speed-profile) ;; *) return 2;; esac
  if [ "$(sdk)" -ge 34 ] 2>/dev/null; then
    pm compile -m "$m" -p PRIORITY_INTERACTIVE_FAST --full -f "$p" 2>/dev/null
  else
    pm compile -m "$m" "$p" 2>/dev/null
  fi
}

network_route(){
  ip route get 1.1.1.1 2>/dev/null | head -1
}

# ---- Foreground / game auto-detection -------------------------------------
foreground_pkg(){
  pkg="$(dumpsys activity activities 2>/dev/null | grep -m1 'mResumedActivity' | grep -oE '[A-Za-z0-9_.]+/[A-Za-z0-9_.]+' | cut -d/ -f1)"
  if [ -z "$pkg" ]; then
    pkg="$(dumpsys window 2>/dev/null | grep -m1 'mCurrentFocus' | grep -oE '[A-Za-z0-9_.]+/[A-Za-z0-9_.]+' | cut -d/ -f1)"
  fi
  if [ -z "$pkg" ]; then
    pkg="$(dumpsys window windows 2>/dev/null | grep -m1 'mFocusedApp' | grep -oE '[A-Za-z0-9_.]+/[A-Za-z0-9_.]+' | cut -d/ -f1)"
  fi
  out "$pkg"
}

game_status_json(){
  fg="$(foreground_pkg)"
  in_list=0
  if [ -n "$fg" ] && [ -f "$STATE/games.list" ] && grep -Fxq "$fg" "$STATE/games.list" 2>/dev/null; then in_list=1; fi
  auto="$(cat "$STATE/auto_game" 2>/dev/null || printf 0)"
  if [ "$auto" = "1" ]; then
    if [ "$in_list" = "1" ] && [ ! -f "$STATE/game_active" ]; then
      cur="$(cat "$STATE/profile" 2>/dev/null || printf balanced)"
      printf '%s\n' "$cur" > "$STATE/pre_game_profile"
      apply_profile performance >/dev/null 2>&1
      printf '%s\n' "$fg" > "$STATE/game_active"
    elif [ "$in_list" != "1" ] && [ -f "$STATE/game_active" ]; then
      prev="$(cat "$STATE/pre_game_profile" 2>/dev/null || printf balanced)"
      apply_profile "$prev" >/dev/null 2>&1
      rm -f "$STATE/game_active" "$STATE/pre_game_profile"
    fi
  fi
  active=0; [ -f "$STATE/game_active" ] && active=1
  printf '{"foreground":"%s","inGameList":%s,"autoGameMode":%s,"gameModeActive":%s}\n' \
    "$(json_escape "$fg")" "$in_list" "$auto" "$active"
}

apply_auto_game(){
  mode="$1"
  case "$mode" in
    on) printf 1 > "$STATE/auto_game";;
    off)
      printf 0 > "$STATE/auto_game"
      if [ -f "$STATE/game_active" ]; then
        prev="$(cat "$STATE/pre_game_profile" 2>/dev/null || printf balanced)"
        apply_profile "$prev" >/dev/null 2>&1
        rm -f "$STATE/game_active" "$STATE/pre_game_profile"
      fi
      ;;
    *) return 2;;
  esac
}

# ---- Background app manager -------------------------------------------------
ignore_list(){ [ -f "$STATE/ignore.list" ] && cat "$STATE/ignore.list"; }
ignore_add(){
  p="$(strip_quotes "$1")"; valid_pkg "$p" || return 2
  grep -Fxq "$p" "$STATE/ignore.list" 2>/dev/null || printf '%s\n' "$p" >> "$STATE/ignore.list"
}
ignore_remove(){
  p="$(strip_quotes "$1")"; valid_pkg "$p" || return 2
  grep -Fvx "$p" "$STATE/ignore.list" > "$STATE/ignore.tmp" 2>/dev/null || :
  mv -f "$STATE/ignore.tmp" "$STATE/ignore.list"
}

close_background(){
  self="frb.axeron.manager"
  fg="$(foreground_pkg)"
  # Common launcher / phone / IME packages are kept alive even if a device
  # reports them via `pm list packages -3`.
  safe_defaults=" com.android.launcher com.android.launcher3 com.google.android.apps.nexuslauncher com.miui.home com.android.dialer com.google.android.dialer com.android.phone com.android.incallui com.android.providers.telephony com.google.android.inputmethod.latin com.touchtype.swiftkey "
  count=0
  pkgs="$(pm list packages -3 2>/dev/null | cut -d: -f2)"
  for p in $pkgs; do
    [ -z "$p" ] && continue
    [ "$p" = "$fg" ] && continue
    [ "$p" = "$self" ] && continue
    grep -Fxq "$p" "$STATE/games.list" 2>/dev/null && continue
    grep -Fxq "$p" "$STATE/ignore.list" 2>/dev/null && continue
    case "$safe_defaults" in *" $p "*) continue;; esac
    am force-stop "$p" >/dev/null 2>&1 && count=$((count+1))
  done
  printf '%s\n' "$count"
}

# ---- Diagnostics ------------------------------------------------------------
thermal_status(){
  dumpsys thermalservice 2>/dev/null | grep -m1 -o 'mStatus=[A-Z_]*' | cut -d= -f2
}
battery_temp(){
  dumpsys battery 2>/dev/null | awk -F': ' '/temperature:/{printf "%.1f", $2/10; exit}'
}
free_storage(){
  df -h /data 2>/dev/null | awk 'NR==2{print $4}'
}

status_json(){
  profile="$(cat "$STATE/profile" 2>/dev/null || printf balanced)"
  dns_mode="$(settings get global private_dns_mode 2>/dev/null)"
  dns_host="$(settings get global private_dns_specifier 2>/dev/null)"
  model="$(getprop ro.product.model 2>/dev/null)"
  brand="$(getprop ro.product.brand 2>/dev/null)"
  manufacturer="$(getprop ro.product.manufacturer 2>/dev/null)"
  os="$(getprop ro.build.version.release 2>/dev/null)"
  s="$(sdk)"
  hyper="$(getprop ro.miui.ui.version.name 2>/dev/null)"
  soc="$(getprop ro.board.platform 2>/dev/null)"
  hz="$(max_refresh)"
  ram="$(ram_mb)"
  render="$(cat "$STATE/render" 2>/dev/null || printf 0)"
  blur="$(cat "$STATE/blur" 2>/dev/null || printf 0)"
  refresh="$(cat "$STATE/refresh" 2>/dev/null || printf 0)"
  network="$(cat "$STATE/network" 2>/dev/null || printf 0)"
  wifi_latency="$(cat "$STATE/wifi_latency" 2>/dev/null || printf 0)"
  memory="$(cat "$STATE/memory" 2>/dev/null || printf 0)"
  auto_game="$(cat "$STATE/auto_game" 2>/dev/null || printf 0)"
  battery="$(dumpsys battery 2>/dev/null | awk -F': ' '/level:/{print $2;exit}')"
  kernel="$(uname -r 2>/dev/null)"
  route="$(network_route)"
  thermal="$(thermal_status)"
  temp="$(battery_temp)"
  free_gb="$(free_storage)"
  printf '{"profile":"%s","model":"%s","brand":"%s","manufacturer":"%s","android":"%s","hyperos":"%s","sdk":"%s","soc":"%s","ramMB":%s,"refreshHz":"%s","cpuGovernor":"%s","dnsMode":"%s","dnsHost":"%s","render":%s,"blur":%s,"highRefresh":%s,"network":%s,"wifiLatency":%s,"memory":%s,"autoGame":%s,"battery":"%s","kernel":"%s","route":"%s","thermal":"%s","batteryTemp":"%s","freeStorage":"%s"}\n' \
    "$(json_escape "$profile")" "$(json_escape "$model")" "$(json_escape "$brand")" "$(json_escape "$manufacturer")" \
    "$(json_escape "$os")" "$(json_escape "$hyper")" "$(json_escape "$s")" "$(json_escape "$soc")" "${ram:-0}" "$(json_escape "$hz")" \
    "$(json_escape "$(cpu_governor)")" "$(json_escape "$dns_mode")" "$(json_escape "$dns_host")" "$render" "$blur" "$refresh" "$network" "$wifi_latency" "$memory" "$auto_game" \
    "$(json_escape "$battery")" "$(json_escape "$kernel")" "$(json_escape "$route")" "$(json_escape "$thermal")" "$(json_escape "$temp")" "$(json_escape "$free_gb")"
}

reset_all(){
  [ -f "$BACKUP/cpu_governors" ] && while IFS='|' read -r f g; do [ -w "$f" ] && printf '%s\n' "$g" > "$f" 2>/dev/null; done < "$BACKUP/cpu_governors"
  [ -f "$BACKUP/gpu_governor" ] && { IFS='|' read -r d g < "$BACKUP/gpu_governor"; [ -w "$d/governor" ] && printf '%s\n' "$g" > "$d/governor" 2>/dev/null; }
  [ -f "$BACKUP/settings" ] && while IFS='|' read -r k v; do [ "$v" = "null" ] && continue; settings put global "$k" "$v" 2>/dev/null; done < "$BACKUP/settings"
  cmd device_config delete activity_manager use_compaction >/dev/null 2>&1
  cmd device_config delete activity_manager process_start_async >/dev/null 2>&1
  cmd device_config delete activity_manager max_previous_time >/dev/null 2>&1
  cmd wifi force-low-latency-mode disabled >/dev/null 2>&1 || true
  for k in debug.sf.multithreaded_present debug.sf.use_frame_rate_priority debug.hwui.initialize_gl_always debug.hwui.early_preload_gl_context debug.hwui.skip_eglmanager_telemetry vendor.perf.gestureflingboost.enable vendor.perf.workloadclassifier.enable persist.sys.background_blur_supported net.tcp.default_init_rwnd; do setprop "$k" "" 2>/dev/null; done
  settings put global private_dns_mode opportunistic 2>/dev/null
  settings put global private_dns_specifier "" 2>/dev/null
  rm -f "$STATE/profile" "$STATE/render" "$STATE/blur" "$STATE/refresh" "$STATE/network" "$STATE/wifi_latency" "$STATE/memory" "$STATE/dns_mode" "$STATE/dns_provider" "$STATE/auto_game" "$STATE/game_active" "$STATE/pre_game_profile"
  printf balanced > "$STATE/profile"; printf auto > "$STATE/dns_mode"; printf 0 > "$STATE/auto_game"
  out "reset=done"
}

case "$1" in
  status) status_json;;
  profile) apply_profile "$2";;
  render) apply_render "$2";;
  blur) apply_blur "$2";;
  refresh) apply_refresh "$2";;
  wifi-latency) apply_wifi_latency "$2";;
  network) apply_network "$2";;
  dns) apply_dns "$2" "$3";;
  memory) apply_memory;;
  trim) trim;;
  fstrim) storage_trim;;
  games-discover) discover_games;;
  games-list) [ -f "$STATE/games.list" ] && cat "$STATE/games.list";;
  game-add) game_add "$2";;
  game-remove) game_remove "$2";;
  game-compile) game_compile "$2" "$3";;
  game-status) game_status_json;;
  auto-game) apply_auto_game "$2";;
  close-bg) close_background;;
  ignore-list) ignore_list;;
  ignore-add) ignore_add "$2";;
  ignore-remove) ignore_remove "$2";;
  optimize) apply_profile performance; apply_render on; apply_refresh on; apply_network on; apply_memory;;
  reset) reset_all;;
  *) out "Xyvonix Core v3.0 CLI"; exit 2;;
esac

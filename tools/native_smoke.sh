#!/usr/bin/env bash
set -euo pipefail
# Bounded Linux package startup; uses isolated local profile directories.
[[ "$(uname -s)" == Linux ]] || { echo "This native smoke checks the Linux export." >&2; exit 1; }
TASK_BUILD="${1:?Pass the absolute export build directory}"
TASK_SMOKE="$TASK_BUILD/standalone-smoke"
TASK_BINARY="$TASK_BUILD/linux/TamHawksProSkater.x86_64"
[[ -x "$TASK_BINARY" ]] || { echo "Linux export executable is missing." >&2; exit 1; }
mkdir -p "$TASK_SMOKE/data" "$TASK_SMOKE/config" "$TASK_SMOKE/cache"
export XDG_DATA_HOME="$TASK_SMOKE/data"
export XDG_CONFIG_HOME="$TASK_SMOKE/config"
export XDG_CACHE_HOME="$TASK_SMOKE/cache"
timeout 45 "$TASK_BINARY" --headless --audio-driver Dummy --quit-after 120 >"$TASK_SMOKE/headless.log" 2>&1
TASK_DISPLAY_PID=""
TASK_GAME_PID=""
cleanup() {
  if [[ -n "$TASK_GAME_PID" ]]; then
    kill "$TASK_GAME_PID" 2>/dev/null || true
    wait "$TASK_GAME_PID" 2>/dev/null || true
  fi
  if [[ -n "$TASK_DISPLAY_PID" ]]; then
    kill "$TASK_DISPLAY_PID" 2>/dev/null || true
    wait "$TASK_DISPLAY_PID" 2>/dev/null || true
  fi
}
trap cleanup EXIT
cat > "$TASK_SMOKE/xorg-1080.conf" <<'XORG'
Section "ServerFlags"
 Option "AutoAddDevices" "false"
 Option "AutoEnableDevices" "false"
 Option "DontVTSwitch" "true"
 Option "PciForceNone" "true"
EndSection
Section "Device"
 Identifier "Dummy"
 Driver "dummy"
 VideoRam 256000
EndSection
Section "Monitor"
 Identifier "Monitor"
 HorizSync 5.0-1000.0
 VertRefresh 5.0-200.0
 Modeline "1920x1080" 148.50 1920 2008 2052 2200 1080 1084 1089 1125 +hsync +vsync
EndSection
Section "Screen"
 Identifier "Screen"
 Device "Dummy"
 Monitor "Monitor"
 DefaultDepth 24
 SubSection "Display"
  Depth 24
  Modes "1920x1080"
 EndSubSection
EndSection
XORG
: > "$TASK_SMOKE/display"
/usr/lib/xorg/Xorg -displayfd 3 -config "$TASK_SMOKE/xorg-1080.conf" -logfile "$TASK_SMOKE/xorg.log" -noreset -nolisten tcp 3>"$TASK_SMOKE/display" >"$TASK_SMOKE/xorg-console.log" 2>&1 &
TASK_DISPLAY_PID=$!
for attempt in {1..50}; do
  [[ -s "$TASK_SMOKE/display" ]] && break
  kill -0 "$TASK_DISPLAY_PID" 2>/dev/null || { cat "$TASK_SMOKE/xorg-console.log"; exit 1; }
  sleep 0.1
done
[[ -s "$TASK_SMOKE/display" ]] || { echo 'Xorg display not ready.' >&2; exit 1; }
export DISPLAY=":$(cat "$TASK_SMOKE/display")"
export LIBGL_ALWAYS_SOFTWARE=1
timeout 90 "$TASK_BINARY" --audio-driver Dummy --resolution 1920x1080 --position 0,0 --quit-after 30 >"$TASK_SMOKE/rendered.log" 2>&1 &
TASK_GAME_PID=$!
wait "$TASK_GAME_PID"
TASK_GAME_PID=""
python3 - "$TASK_SMOKE" <<'PY'
import pathlib,sys
folder=pathlib.Path(sys.argv[1])
for name in ['headless.log','rendered.log']:
 text=(folder/name).read_text()
 if any(x in text for x in ['SCRIPT ERROR:', 'ERROR:', 'Parse Error:']):
  raise SystemExit('Standalone logged an error: '+name+'\n'+text)
 print(name+': normal-boot process exited 0; no script/resource errors.')
print('Normal rendered exit verified. This is a startup smoke, not a performance benchmark.')
PY

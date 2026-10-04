#!/usr/bin/env bash
set -euo pipefail
: "${HOST_CONFIG:?}" "${PRE_START:?}" "${PERSONAL_CONFIG:?}"

# All consumers run against disposable profiles, never the caller's session.
unset HYPRLAND_INSTANCE_SIGNATURE WAYLAND_DISPLAY DISPLAY
profile() {
  export HOME="$TMPDIR/$1/home"
  export XDG_CONFIG_HOME="$TMPDIR/$1/config space"
  export XDG_RUNTIME_DIR="$TMPDIR/$1/run"
  export XDG_CACHE_HOME="$TMPDIR/$1/cache"
  export XDG_DATA_HOME="$TMPDIR/$1/data"
  export XDG_STATE_HOME="$TMPDIR/$1/state"
  mkdir -p "$HOME" "$XDG_RUNTIME_DIR"
  chmod 700 "$XDG_RUNTIME_DIR"
}

check_dms() {
  for name in colors layout outputs cursor windowrules binds; do
    dms config resolve-include hyprland "$name.lua" |
      jq -e '.exists and .included and .configFormat == "lua"'
  done
  dms keybinds show hyprland > "$TMPDIR/binds.json"
  jq -e '.dmsBindsIncluded and .dmsStatus.effective and .dmsStatus.totalIncludes == 7' "$TMPDIR/binds.json"
  jq -e '[.binds[][] | .action] | index("exec xdg-terminal-exec") != null' "$TMPDIR/binds.json"
}

check_hyprland() {
  # Use the real parser without starting a compositor. Only relocate host.lua:
  # /etc has not been activated in the build sandbox (nor on the developer host).
  local dir="${XDG_CONFIG_HOME:-$HOME/.config}/hypr"
  sed "s|/etc/xdg/hypr/host|$TMPDIR/host|g" "$dir/hyprland.lua" > "$dir/verify.lua"
  Hyprland --verify-config --config "$dir/verify.lua"
}

cp "$HOST_CONFIG" "$TMPDIR/host.lua"
profile other-desktop
XDG_CURRENT_DESKTOP=sway "$PRE_START"
test ! -e "$XDG_CONFIG_HOME"

profile fresh
export XDG_CURRENT_DESKTOP=Hyprland
"$PRE_START"
check_dms
for name in colors layout outputs cursor windowrules binds; do
  test -w "$XDG_CONFIG_HOME/hypr/dms/$name.lua"
done
test ! -e "$XDG_CONFIG_HOME/hypr/dms/binds-user.lua"
sha256sum "$XDG_CONFIG_HOME/hypr/"*.lua "$XDG_CONFIG_HOME/hypr/dms/"*.lua > "$TMPDIR/checksums"
"$PRE_START"
sha256sum --check "$TMPDIR/checksums"
check_hyprland

profile hm
mkdir -p "$XDG_CONFIG_HOME/hypr/dms"
ln -s "$PERSONAL_CONFIG" "$XDG_CONFIG_HOME/hypr/hyprland.lua"
printf 'hl.config({ general = { gaps_in = 19 } })\n' > "$XDG_CONFIG_HOME/hypr/dms/layout.lua"
"$PRE_START"
test "$(readlink "$XDG_CONFIG_HOME/hypr/hyprland.lua")" = "$PERSONAL_CONFIG"
grep -Fx 'hl.config({ general = { gaps_in = 19 } })' "$XDG_CONFIG_HOME/hypr/dms/layout.lua"
check_dms
check_hyprland

profile existing
mkdir -p "$XDG_CONFIG_HOME/hypr/dms"
ln -s "$TMPDIR/missing-main" "$XDG_CONFIG_HOME/hypr/hyprland.lua"
: > "$XDG_CONFIG_HOME/hypr/dms/colors.lua"
printf 'invalid lua\n' > "$XDG_CONFIG_HOME/hypr/dms/layout.lua"
ln -s "$TMPDIR/missing-fragment" "$XDG_CONFIG_HOME/hypr/dms/outputs.lua"
"$PRE_START"
test "$(readlink "$XDG_CONFIG_HOME/hypr/hyprland.lua")" = "$TMPDIR/missing-main"
test "$(readlink "$XDG_CONFIG_HOME/hypr/dms/outputs.lua")" = "$TMPDIR/missing-fragment"
test ! -e "$TMPDIR/missing-main" && test ! -e "$TMPDIR/missing-fragment"
test ! -s "$XDG_CONFIG_HOME/hypr/dms/colors.lua"
grep -Fx 'invalid lua' "$XDG_CONFIG_HOME/hypr/dms/layout.lua"

profile invalid
"$PRE_START"
printf 'invalid lua\n' > "$XDG_CONFIG_HOME/hypr/dms/layout.lua"
"$PRE_START"
if check_hyprland; then
  echo 'The real compositor parser must reject the preserved malformed fragment' >&2
  exit 1
fi

profile legacy
mkdir -p "$XDG_CONFIG_HOME/hypr"
printf '# personal legacy config\n' > "$XDG_CONFIG_HOME/hypr/hyprland.conf"
"$PRE_START"
test ! -e "$XDG_CONFIG_HOME/hypr/hyprland.lua"
test ! -e "$XDG_CONFIG_HOME/hypr/dms"
grep -Fx '# personal legacy config' "$XDG_CONFIG_HOME/hypr/hyprland.conf"

profile default-xdg
unset XDG_CONFIG_HOME
"$PRE_START"
test -f "$HOME/.config/hypr/hyprland.lua"
check_dms

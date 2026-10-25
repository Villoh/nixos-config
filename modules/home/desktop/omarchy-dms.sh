# omarchy-dms: Omarchy themes as dmsProfiles looks. The Nix wrapper exports
# OMARCHY_THEMES (Omarchy's own themes/) and puts the tools used below on PATH.
wall="$HOME/Pictures/Wallpapers/omarchy"
themes="$HOME/.config/DankMaterialShell/themes"
tmp=""
restore=0
force=0

usage() {
  cat <<'EOF'
usage: omarchy-dms sync [--force]       create profiles for Omarchy's own themes
                                        (--force recreates the ones that exist)
       omarchy-dms install [repo]       install a community theme (owner/repo or git
                                        URL; no argument opens a picker over the
                                        omarchy.org/themes list) and create its profile
       omarchy-dms list                 repos listed on omarchy.org/themes
EOF
}

finish() {
  [ -z "$tmp" ] || rm -rf "$tmp"
  [ "$restore" = 0 ] || dms ipc call profiles setOption autosave true >/dev/null
}
trap finish EXIT

# Trailing slash: built-in theme folders are symlinks into the Nix store.
first_image() { find "$wall/$1/" -maxdepth 1 -type f 2>/dev/null | sort | sed -n 1p || true; }

has_profile() { grep -qF -e "\"$1\"" -e "\"$2\"" <<<"$existing"; }

create() {
  echo "create: $1"
  dms ipc call profiles create "$1" >/dev/null
  sleep 1.5
}

# Autosave would write each theme change into the previously created profile.
begin() {
  existing=$(dms ipc call profiles list)
  restore=1
  dms ipc call profiles setOption autosave false >/dev/null
  dms ipc call profiles setOption applyCommand "$(command -v omarchy-dms) hook" >/dev/null
  # Snapshot of the current look first, to switch back to it.
  has_profile Original original || create Original
}

make() {
  local slug=$1 colors=$2 name img out
  name=$(sed 's/-/ /g; s/\b./\u&/g' <<<"$slug")
  if has_profile "$name" "$slug"; then
    if [ "$force" = 0 ]; then
      echo "skip: $name"
      return
    fi
    dms ipc call profiles remove "$slug" >/dev/null
    sleep 1.5
  fi
  dms ipc call profiles customTheme "$themes/omarchy-$slug/theme.json" "omarchy-$slug" default default default both >/dev/null
  dms ipc call theme "$(omarchy-dms-theme-json --mode "$colors")" >/dev/null
  img=$(first_image "$slug")
  if [ -n "$img" ]; then
    out=$(dms ipc call wallpaper set "$img")
    case $out in ERROR*) echo "$out" >&2; exit 1 ;; esac
  fi
  sleep 1.5
  create "$name"
}

# Applied by dmsProfiles after a switch: a profile carries one wallpaper copy
# (plus its thumb.jpg), which is all the carousel would list. Point back at the
# theme folder so it lists the whole set. dmsProfiles runs this command *before*
# it sets the profile's own wallpaper, so the change has to land a bit later,
# from a detached process (the command must return for the switch to finish).
hook() {
  [ -n "${DMS_PROFILE_SLUG:-}" ] && [ -d "$wall/$DMS_PROFILE_SLUG" ] || exit 0
  local img
  img=$(first_image "$DMS_PROFILE_SLUG")
  # shellcheck disable=SC2016 # $1 is meant for the inner sh, not this shell
  [ -z "$img" ] ||
    setsid -f sh -c 'sleep 2; exec dms ipc call wallpaper set "$1"' _ "$img" >/dev/null 2>&1 </dev/null
}

sync() {
  local colors
  [ "${1:-}" != --force ] || force=1
  begin
  for colors in "$OMARCHY_THEMES"/*/colors.toml; do
    make "$(basename "$(dirname "$colors")")" "$colors"
  done
}

list() {
  curl -fsSL https://omarchy.org/themes/ |
    grep -oE 'https://github\.com/[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+' |
    sed 's#https://github.com/##' | grep -vE '^(basecamp|omacom)/' | sort -u
}

install() {
  local arg=${1:-} url slug
  [ -n "$arg" ] || arg=$(list | fzf --prompt='omarchy theme> ')
  case $arg in
    https://* | ssh://* | git@*) url=$arg ;;
    */*) url=https://github.com/$arg ;;
    *) echo "expected owner/repo or a git URL" >&2; exit 1 ;;
  esac
  # Same naming as omarchy-theme-install, and safe to use as a path.
  slug=$(basename -- "${arg%.git}" | sed -E 's/^omarchy-//; s/-theme$//' | tr '[:upper:]' '[:lower:]')
  if ! (LC_ALL=C; [[ $slug =~ ^[a-z0-9_][a-z0-9._+-]*$ ]]); then
    echo "unusable theme name: $slug" >&2
    exit 1
  fi
  # Built-in themes are read-only links into the Nix store.
  if [ -L "$themes/omarchy-$slug/theme.json" ] || [ -L "$wall/$slug" ]; then
    echo "$slug is one of Omarchy's built-in themes" >&2
    exit 1
  fi

  tmp=$(mktemp -d)
  git clone --depth 1 -- "$url" "$tmp/repo"
  if [ ! -f "$tmp/repo/colors.toml" ]; then
    echo "$arg has no colors.toml (alacritty-only themes are not supported)" >&2
    exit 1
  fi

  mkdir -p "$themes/omarchy-$slug" "$wall/$slug"
  omarchy-dms-theme-json "$tmp/repo/colors.toml" "$slug" "$themes/omarchy-$slug"
  if [ -d "$tmp/repo/backgrounds" ]; then
    find "$tmp/repo/backgrounds" -maxdepth 1 -type f -size +2k \
      \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) \
      -exec cp -f {} "$wall/$slug/" \;
  fi

  begin
  force=1 # reinstalling refreshes the profile
  make "$slug" "$tmp/repo/colors.toml"
}

case ${1:-} in
  sync) sync "${2:-}" ;;
  install) install "${2:-}" ;;
  list) list ;;
  hook) hook ;;
  *) usage; exit 1 ;;
esac

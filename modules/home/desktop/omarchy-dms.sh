# omarchy-dms: Omarchy themes as dmsProfiles looks. The Nix wrapper exports
# OMARCHY_THEMES (Omarchy's own themes/) and puts the tools used below on PATH.
wall="$HOME/Pictures/Wallpapers/omarchy"
themes="$HOME/.config/DankMaterialShell/themes"
tmp=""
restore=0
force=0

usage() {
  cat <<'EOF'
usage: omarchy-dms sync [--force] [theme...]
                                        create profiles for Omarchy's own themes (all,
                                        or just the ones named); --force recreates
                                        the ones that exist
       omarchy-dms install [repo]       install a community theme (owner/repo or git
                                        URL; no argument opens a picker over the
                                        omarchy.org/themes list) and create its profile
       omarchy-dms update [theme...]    refresh themes installed with install (all, or
                                        just the ones named)
       omarchy-dms remove [-y] [theme...]
                                        remove theme, wallpapers and profile (no
                                        argument: pick with fzf, Tab marks several).
                                        Built-in themes only lose their profile.
       omarchy-dms installed            every theme, where it comes from, profile or not
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

name_of() { sed 's/-/ /g; s/\b./\u&/g' <<<"$1"; }

has_word() {
  local w=$1 x
  shift
  for x in "$@"; do [ "$x" = "$w" ] && return 0; done
  return 1
}

# Slugs of every Omarchy theme folder in DMS (built-in and community).
slugs() {
  local d b
  for d in "$themes"/omarchy-*/; do
    [ -f "$d/theme.json" ] || continue
    b=$(basename "$d")
    echo "${b#omarchy-}"
  done
}

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
  name=$(name_of "$slug")
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
  local colors a s only=()
  for a in "$@"; do
    case $a in
      --force) force=1 ;;
      *)
        [ -f "$OMARCHY_THEMES/$a/colors.toml" ] || { echo "not an Omarchy theme: $a" >&2; exit 1; }
        only+=("$a")
        ;;
    esac
  done
  begin
  for colors in "$OMARCHY_THEMES"/*/colors.toml; do
    s=$(basename "$(dirname "$colors")")
    [ "${#only[@]}" -eq 0 ] || has_word "$s" "${only[@]}" || continue
    make "$s" "$colors"
  done
}

list() {
  curl -fsSL https://omarchy.org/themes/ |
    grep -oE 'https://github\.com/[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+' |
    sed 's#https://github.com/##' | grep -vE '^(basecamp|omacom)/' | sort -u
}

# Same naming as omarchy-theme-install.
slug_of() { basename -- "${1%.git}" | sed -E 's/^omarchy-//; s/-theme$//' | tr '[:upper:]' '[:lower:]'; }

# Clone URL and (re)write the theme folder and wallpapers for SLUG, leaving the
# clone in $tmp. Explicit returns: update calls it under `||`, where set -e is off.
fetch() {
  local url=$1 slug=$2
  # Safe to use as a path.
  if ! (LC_ALL=C; [[ $slug =~ ^[a-z0-9_][a-z0-9._+-]*$ ]]); then
    echo "unusable theme name: $slug" >&2
    return 1
  fi
  # Built-in themes are read-only links into the Nix store.
  if [ -L "$themes/omarchy-$slug/theme.json" ] || [ -L "$wall/$slug" ]; then
    echo "$slug is one of Omarchy's built-in themes" >&2
    return 1
  fi

  [ -z "$tmp" ] || rm -rf "$tmp"
  tmp=$(mktemp -d)
  git clone --quiet --depth 1 -- "$url" "$tmp/repo" || return 1
  if [ ! -f "$tmp/repo/colors.toml" ]; then
    echo "$url has no colors.toml (alacritty-only themes are not supported)" >&2
    return 1
  fi

  mkdir -p "$themes/omarchy-$slug" "$wall/$slug"
  omarchy-dms-theme-json "$tmp/repo/colors.toml" "$slug" "$themes/omarchy-$slug" || return 1
  if [ -d "$tmp/repo/backgrounds" ]; then
    find "$tmp/repo/backgrounds" -maxdepth 1 -type f -size +2k \
      \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) \
      -exec cp -f {} "$wall/$slug/" \;
  fi
  # Remembered so `update` can fetch it again.
  printf '%s\n' "$url" >"$themes/omarchy-$slug/.source"
}

install() {
  local arg=${1:-} url slug
  [ -n "$arg" ] || arg=$(list | fzf --prompt='omarchy theme> ')
  case $arg in
    https://* | ssh://* | git@*) url=$arg ;;
    */*) url=https://github.com/$arg ;;
    *) echo "expected owner/repo or a git URL" >&2; exit 1 ;;
  esac
  slug=$(slug_of "$arg")
  fetch "$url" "$slug" || exit 1

  begin
  force=1 # reinstalling refreshes the profile
  make "$slug" "$tmp/repo/colors.toml"
}

# Refresh the files of the themes installed with `install` (all, or those named).
# Profiles are left alone: they point at theme.json by path, so the colors
# follow; `install` again to also refresh a profile's own wallpaper copy.
update() {
  local src url slug n=0 a
  for a in "$@"; do
    [ -f "$themes/omarchy-$a/.source" ] || echo "not updatable (no .source): $a" >&2
  done
  for src in "$themes"/omarchy-*/.source; do
    [ -f "$src" ] || continue
    url=$(<"$src")
    slug=$(basename "$(dirname "$src")")
    slug=${slug#omarchy-}
    [ $# -eq 0 ] || has_word "$slug" "$@" || continue
    echo "update: $slug ($url)"
    fetch "$url" "$slug" || echo "failed: $slug" >&2
    n=$((n + 1))
  done
  [ "$n" -gt 0 ] || echo "no installed community themes (reinstall them once with: omarchy-dms install <repo>)"
}

installed() {
  local slug kind prof
  existing=$(dms ipc call profiles list)
  for slug in $(slugs); do
    if [ -L "$themes/omarchy-$slug/theme.json" ]; then
      kind=built-in
    elif [ -f "$themes/omarchy-$slug/.source" ]; then
      kind=$(<"$themes/omarchy-$slug/.source")
    else
      kind="community (no .source: reinstall to track)"
    fi
    if has_profile "$(name_of "$slug")" "$slug"; then prof=profile; else prof=-; fi
    printf '%-22s %-8s %s\n' "$slug" "$prof" "$kind"
  done
}

remove() {
  local yes=0 sel=() known=() a slug active ans
  for a in "$@"; do
    case $a in
      -y) yes=1 ;;
      *) sel+=("$a") ;;
    esac
  done
  mapfile -t known < <(slugs)
  if [ "${#sel[@]}" -eq 0 ]; then
    mapfile -t sel < <(printf '%s\n' "${known[@]}" | fzf -m --prompt='remove (Tab marks)> ' || true)
  fi
  [ "${#sel[@]}" -gt 0 ] || exit 0
  # Names are checked against the folders that exist: nothing else reaches rm.
  for slug in "${sel[@]}"; do
    has_word "$slug" "${known[@]}" || { echo "unknown theme: $slug" >&2; exit 1; }
  done
  if [ "$yes" = 0 ]; then
    printf 'remove: %s\n' "${sel[*]}"
    read -r -p 'continue? [y/N] ' ans
    [ "$ans" = y ] || exit 0
  fi

  existing=$(dms ipc call profiles list)
  active=$(dms ipc call profiles status | sed -n 's/.*"active":"\([^"]*\)".*/\1/p')
  restore=1
  dms ipc call profiles setOption autosave false >/dev/null
  for slug in "${sel[@]}"; do
    if has_profile "$(name_of "$slug")" "$slug"; then
      # Leave the profile before deleting it.
      if [ "$active" = "$slug" ] && has_profile Original original; then
        dms ipc call profiles apply original >/dev/null
        active=original
        sleep 3
      fi
      dms ipc call profiles remove "$slug" >/dev/null
      sleep 1.5
    fi
    if [ -L "$themes/omarchy-$slug/theme.json" ]; then
      echo "removed profile: $slug (built-in files are managed by Nix; sync recreates it)"
    else
      rm -rf "${themes:?}/omarchy-$slug" "${wall:?}/$slug"
      echo "removed: $slug"
    fi
  done
}

case ${1:-} in
  sync) shift; sync "$@" ;;
  install) install "${2:-}" ;;
  update) shift; update "$@" ;;
  remove) shift; remove "$@" ;;
  installed) installed ;;
  list) list ;;
  hook) hook ;;
  *) usage; exit 1 ;;
esac

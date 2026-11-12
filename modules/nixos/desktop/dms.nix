{ lib, pkgs, ... }:

let
  dux-shell = pkgs.dux-shell.overrideAttrs (old: {
    postPatch = (old.postPatch or "") + ''
      chmod -R u+w ../quickshell

      # Each edit must change its file: when an upstream update moves the text a
      # pattern looks for, the build fails here instead of dropping the patch.
      edit() {
        local file=$1
        shift
        cp "$file" "$file.orig"
        sed -i "$@" "$file"
        if cmp -s "$file" "$file.orig"; then
          echo "dux-shell: patch no longer applies to $file: $*" >&2
          exit 1
        fi
        rm "$file.orig"
      }

      # Zed theme: recolor the generated template (keyword, comment, type, ghost
      # element hover/selected) with Material You roles instead of the dank16 palette.
      template=../quickshell/matugen/templates/dank-zed.json
      for mode in dark light; do
        edit "$template" -e "/\"keyword\": {/,/\"font_style\"/s/dank16.color5.$mode.hex/colors.secondary.$mode.hex/"
        edit "$template" -e "/\"comment\": {/,/\"font_style\"/s/dank16.color8.$mode.hex/colors.on_surface_variant.$mode.hex/"
        edit "$template" -e "/\"comment.doc\": {/,/\"font_style\"/s/dank16.color8.$mode.hex/colors.on_surface_variant.$mode.hex/"
        edit "$template" -e "/\"type\": {/,/\"font_style\"/s/dank16.color3.$mode.hex/colors.primary.$mode.hex/"
      done
      edit "$template" \
        -e 's/\("ghost_element.selected": "{{colors.\)secondary_container\(\.\(dark\|light\)\.hex}}\)80"/\1primary\24D"/'
      edit "$template" \
        -e 's/\("ghost_element.hover": "{{colors.\)surface_container\(\.\(dark\|light\)\.hex}}\)80"/\1primary\24D"/'

      # GTK: the headerbar, its backdrop and the window share one color, so GTK/Chromium
      # apps (Brave) can't tell the focused window from the rest, even after pressing
      # "Apply GTK colors". The focused headerbar gets the next raised surface and
      # unfocused text is dimmed (same values adw-gtk3 uses).
      tpl=../quickshell/matugen/templates/gtk-colors.css
      edit "$tpl" -e 's/\(headerbar_bg_color {{colors\.\)surface_container\./\1surface_container_high./'
      edit "$tpl" -e 's/\(theme_unfocused_fg_color \)@window_fg_color;/\1mix(@window_fg_color,@window_bg_color,0.5);/'

      # Toasts: start expanded and stay longer (info 1.5s -> 5s, warning 3s -> 6s).
      # Durations are hardcoded in ToastService.qml; replace with a setting if
      # upstream adds one.
      edit ../quickshell/Modules/Toast.qml -e 's/property bool expanded: false/property bool expanded: true/'
      edit ../quickshell/Modules/Toast.qml -e 's/toast.expanded = false;/toast.expanded = true;/'
      edit ../quickshell/Services/ToastService.qml -e 's/levelWarn ? 3000 : 1500/levelWarn ? 6000 : 5000/'
    '';
  });
in
{
  # Shared AT-SPI2 accessibility bus, available without a personal profile.
  services.gnome.at-spi2-core.enable = true;
  services.gnome.gnome-keyring.enable = true;
  # The enable above only hooks PAM `login`; greeter logins go through `greetd`.
  security.pam.services.greetd.enableGnomeKeyring = true;

  programs.dux-shell = {
    # mkDefault so a host can switch to Noctalia with a plain `enable = false`.
    enable = lib.mkDefault true;
    package = dux-shell;
    systemd = {
      enable = true;
      # UWSM starts graphical-session.target for the logged-in compositor.
      target = "graphical-session.target";
    };
  };

  # Filesystem index for the launcher Files tab; runs as a user service.
  programs.dux-search = {
    enable = true;
    systemd.target = "graphical-session.target";
  };

  # Standalone suite apps. Neither starts with the session: dux-calendar's
  # systemd.enable keeps it syncing with reminders, and dux-files' portal.enable
  # registers its file chooser (selected in portals.nix).
  programs.dux-calendar.enable = true;
  programs.dux-files.enable = true;

  environment.systemPackages = [
    pkgs.dux-gop
    pkgs.pulseaudio # pactl: Dux Shell audio port and profile switching (PipeWire remains enabled).
    pkgs.adw-gtk3
  ];
}

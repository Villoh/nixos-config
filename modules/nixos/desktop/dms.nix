{ lib, pkgs, ... }:

let
  dms-shell = pkgs.dms-shell.overrideAttrs (old: {
    postPatch = (old.postPatch or "") + ''
      chmod -R u+w ../quickshell

      # Zed theme: recolor the generated template (keyword, comment, type, ghost
      # element hover/selected) with Material You roles instead of the dank16 palette.
      # These sed patterns fail silently if upstream changes the template; recheck
      # the Zed theme after DMS updates.
      template=../quickshell/matugen/templates/dank-zed.json
      sed -i \
        -e '/"keyword": {/,/"font_style"/s/dank16.color5.dark.hex/colors.secondary.dark.hex/' \
        -e '/"keyword": {/,/"font_style"/s/dank16.color5.light.hex/colors.secondary.light.hex/' \
        -e 's/\("ghost_element.selected": "{{colors.\)secondary_container\(\.\(dark\|light\)\.hex}}\)80"/\1primary\24D"/' \
        -e 's/\("ghost_element.hover": "{{colors.\)surface_container\(\.\(dark\|light\)\.hex}}\)80"/\1primary\24D"/' \
        -e '/"comment": {/,/"font_style"/s/dank16.color8.dark.hex/colors.on_surface_variant.dark.hex/' \
        -e '/"comment": {/,/"font_style"/s/dank16.color8.light.hex/colors.on_surface_variant.light.hex/' \
        -e '/"comment.doc": {/,/"font_style"/s/dank16.color8.dark.hex/colors.on_surface_variant.dark.hex/' \
        -e '/"comment.doc": {/,/"font_style"/s/dank16.color8.light.hex/colors.on_surface_variant.light.hex/' \
        -e '/"type": {/,/"font_style"/s/dank16.color3.dark.hex/colors.primary.dark.hex/' \
        -e '/"type": {/,/"font_style"/s/dank16.color3.light.hex/colors.primary.light.hex/' \
        "$template"

      # Toasts: start expanded and stay longer (info 1.5s -> 5s, warning 3s -> 6s).
      # DMS 1.6.2 has no setting for this: durations are hardcoded in ToastService.qml.
      # Kept as sed on purpose; fails silently if upstream changes those lines, so
      # recheck after DMS updates. Replace with a setting if upstream adds one.
      sed -i \
        -e 's/property bool expanded: false/property bool expanded: true/' \
        -e 's/toast.expanded = false;/toast.expanded = true;/' \
        ../quickshell/Modules/Toast.qml
      sed -i \
        -e 's/levelWarn ? 3000 : 1500/levelWarn ? 6000 : 5000/' \
        ../quickshell/Services/ToastService.qml
    '';
  });
in
{
  # Shared AT-SPI2 accessibility bus, available without a personal profile.
  services.gnome.at-spi2-core.enable = true;
  services.gnome.gnome-keyring.enable = true;
  # The enable above only hooks PAM `login`; greeter logins go through `greetd`.
  security.pam.services.greetd.enableGnomeKeyring = true;

  programs.dms-shell = {
    # mkDefault so a host can switch to Noctalia with a plain `enable = false`.
    enable = lib.mkDefault true;
    package = dms-shell;
    systemd = {
      enable = true;
      # UWSM starts graphical-session.target for the logged-in compositor.
      target = "graphical-session.target";
    };
  };

  # Filesystem index for the DMS launcher Files tab; runs as a user service.
  programs.dsearch = {
    enable = true;
    systemd.target = "graphical-session.target";
  };

  environment.systemPackages = [
    pkgs.dgop
    pkgs.pulseaudio # pactl: DMS audio port and profile switching (PipeWire remains enabled).
    pkgs.adw-gtk3
  ];
}

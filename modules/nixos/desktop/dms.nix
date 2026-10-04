{ pkgs, ... }:

let
  dms-shell = pkgs.dms-shell.overrideAttrs (old: {
    postPatch = (old.postPatch or "") + ''
      chmod -R u+w ../quickshell
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
    '';
  });
in
{
  # Shared AT-SPI2 accessibility bus, available without a personal profile.
  services.gnome.at-spi2-core.enable = true;
  services.gnome.gnome-keyring.enable = true;

  programs.dms-shell = {
    enable = true;
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

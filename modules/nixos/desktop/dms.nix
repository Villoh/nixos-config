{
  config,
  inputs,
  pkgs,
  ...
}:

let
  dms-shell = pkgs.dms-shell.overrideAttrs (old: {
    postPatch = (old.postPatch or "") + ''
      chmod -R u+w ../quickshell
      template=../quickshell/matugen/templates/dank-zed.json
      sed -i \
        -e '/"keyword": {/,/"font_style"/s/dank16.color5.dark.hex/colors.secondary.dark.hex/' \
        -e '/"keyword": {/,/"font_style"/s/dank16.color5.light.hex/colors.secondary.light.hex/' \
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
  imports = [ inputs.dms-plugin-registry.nixosModules.default ];

  # Provides the AT-SPI2 accessibility bus required by Pi computer-use.
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
    plugins = {
      bitwarden.enable = true;
      dankKDEConnect.enable = true;
      quickCapture.enable = true;
      wallpaperCarousel.enable = true;
      dockerManager.enable = true;
      dankscale.enable = true;
      aiOverviewControl.enable = true;
      dmsProfiles.enable = true;
      cliproxyQuota.enable = true;
      commandRunner.enable = true;
      nixPackageRunner.enable = true;
    };
  };

  # Native DMS System Updates widget uses TERMINAL to launch update commands.
  systemd.user.services.dms.environment.TERMINAL =
    config.home-manager.users.mikel.home.sessionVariables.TERMINAL;

  environment.systemPackages = [
    pkgs.dgop
    pkgs.dsearch
    pkgs.pulseaudio # pactl: DMS audio port and profile switching (PipeWire remains enabled).
    pkgs.qt6Packages.qt6ct
    pkgs.adw-gtk3
    inputs.dankcalendar.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];
}

{ config, inputs, pkgs, ... }:

{
  imports = [ inputs.dms-plugin-registry.nixosModules.default ];

  # Provides the AT-SPI2 accessibility bus required by Pi computer-use.
  services.gnome.at-spi2-core.enable = true;

  programs.dms-shell = {
    enable = true;
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
    };
  };

  # Native DMS System Updates widget uses TERMINAL to launch update commands.
  systemd.user.services.dms.environment.TERMINAL =
    config.home-manager.users.mikel.home.sessionVariables.TERMINAL;

  environment.systemPackages = [
    pkgs.dgop
    pkgs.dsearch
    pkgs.qt6Packages.qt6ct
    pkgs.adw-gtk3
    inputs.dankcalendar.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];
}

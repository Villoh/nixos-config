{ inputs, pkgs, ... }:

{
  # Provides the AT-SPI2 accessibility bus required by Pi computer-use.
  services.gnome.at-spi2-core.enable = true;

  programs.dms-shell = {
    enable = true;
    systemd = {
      enable = true;
      target = "hyprland-session.target";
    };
  };

  environment.systemPackages = [
    pkgs.dgop
    pkgs.dsearch
    inputs.dankcalendar.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];
}

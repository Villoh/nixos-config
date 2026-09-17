{ inputs, pkgs, ... }:

{
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

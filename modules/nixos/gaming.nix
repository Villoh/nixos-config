{ pkgs, ... }:

{
  programs.steam = {
    enable = true;
    gamescopeSession.enable = true;
    extraCompatPackages = [ pkgs.proton-ge-bin ];
  };

  programs.gamemode.enable = true;

  environment.systemPackages = with pkgs; [
    heroic
    lutris
    wineWow64Packages.stable
    winetricks
    protonup-qt
    protonplus
    mangohud
    goverlay
  ];
}

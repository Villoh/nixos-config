{ pkgs, ... }:

{
  home.packages = with pkgs; [
    heroic
    hydralauncher
    lutris
    protonup-qt
    protonplus
    protontricks
    mangohud
    goverlay
    wineWow64Packages.stable
    winetricks
  ];
}

{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    heroic
    hydralauncher
    lutris
    protonup-qt
    protonplus
    mangohud
    goverlay
    wineWow64Packages.stable
    winetricks
  ];
}

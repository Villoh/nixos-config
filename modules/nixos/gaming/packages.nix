{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    heroic
    lutris
    protonup-qt
    protonplus
    mangohud
    goverlay
    wineWow64Packages.stable
    winetricks
  ];
}

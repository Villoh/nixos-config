{ pkgs, ... }:

{
  home.packages = with pkgs; [
    filen-cli
    filen-desktop
  ];
}

{ pkgs, ... }:

{
  home-manager.users.mikel.home.packages = with pkgs; [
    filen-cli
    filen-desktop
  ];
}

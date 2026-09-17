{ pkgs, ... }:

{
  home-manager.users.mikel.home.packages = with pkgs; [
    handy
    wtype
  ];
}

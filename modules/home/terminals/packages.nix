{ pkgs, ... }:

{
  home-manager.users.mikel.home.packages = with pkgs; [
    yazi
    superfile
    nerd-fonts.jetbrains-mono
  ];
}

{ pkgs, ... }:

{
  home.packages = with pkgs; [
    yazi
    superfile
    nerd-fonts.jetbrains-mono
  ];
}

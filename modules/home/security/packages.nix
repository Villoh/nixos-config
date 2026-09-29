{ pkgs, ... }:

{
  home-manager.users.mikel.home.packages = with pkgs; [
    bitwarden-cli
    seahorse
    gnupg
    nssTools
    pinentry-qt
    veracrypt
  ];
}

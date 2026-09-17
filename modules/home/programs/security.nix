{ pkgs, ... }:

{
  home-manager.users.mikel.home.packages = with pkgs; [
    bitwarden-cli
    gnupg
    nssTools
    pinentry-qt
    veracrypt
  ];
}

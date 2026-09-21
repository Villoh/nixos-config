{ pkgs, ... }:

{
  home-manager.users.mikel.home.packages = with pkgs; [
    bitwarden-cli
    wl-clipboard
    gnupg
    nssTools
    pinentry-qt
    veracrypt
  ];
}

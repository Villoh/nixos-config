{ pkgs, ... }:

{
  home.packages = with pkgs; [
    bitwarden-cli
    libsecret
    pinentry-qt # Bitwarden DMS plugin types the master password here, outside the shell.
    seahorse
    gnupg
    nssTools
    veracrypt
  ];
}

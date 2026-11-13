{ pkgs, ... }:

{
  home.packages = with pkgs; [
    bitwarden-cli
    # Official client (Electron). BitRitter (native GTK4, Rust) was tried in 2026-11 and
    # aborts on organization items: InvalidMac on decrypt, a known upstream limitation.
    bitwarden-desktop
    libsecret
    pinentry-qt # Bitwarden DMS plugin types the master password here, outside the shell.
    seahorse
    gnupg
    nssTools
    veracrypt
  ];
}

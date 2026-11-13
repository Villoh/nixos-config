{ pkgs, ... }:

{
  home.packages = with pkgs; [
    bitwarden-cli
    # Trial: native GTK4 Bitwarden/Vaultwarden client (Rust). Fallback: the official
    # bitwarden-desktop (Electron).
    bitritter
    libsecret
    pinentry-qt # Bitwarden DMS plugin types the master password here, outside the shell.
    seahorse
    gnupg
    nssTools
    veracrypt
  ];
}

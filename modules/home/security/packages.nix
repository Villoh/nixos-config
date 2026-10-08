{ pkgs, ... }:

{
  home.packages = with pkgs; [
    bitwarden-cli
    libsecret
    seahorse
    gnupg
    nssTools
    veracrypt
  ];
}

{ pkgs, ... }:

{
  home.packages = with pkgs; [
    bitwarden-cli
    seahorse
    gnupg
    nssTools
    veracrypt
  ];
}

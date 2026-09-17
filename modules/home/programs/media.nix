{ inputs, pkgs, ... }:

{
  home-manager.users.mikel.home.packages = [
    inputs.ytm-player.packages.${pkgs.stdenv.hostPlatform.system}.default
    pkgs.imv
    pkgs.mpv
  ];
}

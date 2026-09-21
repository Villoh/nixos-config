{ inputs, pkgs, ... }:

{
  home-manager.users.mikel.home.packages = [
    inputs.ytm-player.packages.${pkgs.stdenv.hostPlatform.system}.default
    pkgs.imv
    pkgs.mpv
    pkgs.gpu-screen-recorder
    pkgs.wf-recorder
    pkgs.ffmpeg
    pkgs.imagemagick
    pkgs.img2pdf
    pkgs.tesseract
    pkgs.zbar
  ];
}

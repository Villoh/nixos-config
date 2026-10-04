{ inputs, pkgs, ... }:

{
  home.packages = [
    inputs.ytm-player.packages.${pkgs.stdenv.hostPlatform.system}.ytm-player-full
    pkgs.imv
    pkgs.mpv
    pkgs.obs-studio
    pkgs.gpu-screen-recorder
    pkgs.wf-recorder
    pkgs.ffmpeg
    pkgs.yt-dlp
    pkgs.imagemagick
    pkgs.img2pdf
    pkgs.tesseract
    pkgs.zbar
  ];
}

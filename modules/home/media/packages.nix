{ inputs, pkgs, ... }:

{
  home.packages = [
    inputs.ytm-player.packages.${pkgs.stdenv.hostPlatform.system}.ytm-player-full
    inputs.sonora.packages.${pkgs.stdenv.hostPlatform.system}.sonora
    # PENDING: cache. Source build (GPUI, about 2,200 derivations), swapped for the nightly
    # binary built from the same commit meanwhile.
    # inputs.kopuz.packages.${pkgs.stdenv.hostPlatform.system}.kopuz
    pkgs.kopuz-bin
    pkgs.meiro
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

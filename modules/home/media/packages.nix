{ inputs, pkgs, ... }:

{
  home.packages = [
    inputs.ytm-player.packages.${pkgs.stdenv.hostPlatform.system}.ytm-player-full
    inputs.sonora.packages.${pkgs.stdenv.hostPlatform.system}.sonora
    # Source build served by kopuz.cachix.org (modules/nixos/core/nix.nix).
    inputs.kopuz.packages.${pkgs.stdenv.hostPlatform.system}.kopuz
    pkgs.meiro
    pkgs.imv
    pkgs.mpv
    pkgs.wf-recorder
    pkgs.ffmpeg
    pkgs.frame-media-converter
    pkgs.yt-dlp
    pkgs.imagemagick
    pkgs.img2pdf
    pkgs.tesseract
    pkgs.zbar
    # DMS Screen Capture Toolbar: capture, region selection, editor and notifications.
    pkgs.grim
    pkgs.slurp
    pkgs.satty
    pkgs.libnotify
  ];
}

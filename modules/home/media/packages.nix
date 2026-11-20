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
    # PlayStation Remote Play client (replaces the capture card for PS streaming).
    # The global QT_STYLE_OVERRIDE=breeze makes its QML UI fail to load ("module breeze is
    # not installed") and the app exits silently, so unset it for this app only.
    (pkgs.symlinkJoin {
      name = "chiaki-ng";
      paths = [ pkgs.chiaki-ng ];
      nativeBuildInputs = [ pkgs.makeWrapper ];
      postBuild = "wrapProgram $out/bin/chiaki --unset QT_STYLE_OVERRIDE";
    })
    pkgs.ffmpeg
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

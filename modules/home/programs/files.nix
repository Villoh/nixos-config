{ pkgs, ... }:

{
  home-manager.users.mikel.home.packages = with pkgs; [
    kdePackages.dolphin
    kdePackages.ark
    kdePackages.okular
    onlyoffice-desktopeditors
    fastfetch
    gpu-screen-recorder
    wf-recorder
    ffmpeg
    imagemagick
    img2pdf
    tesseract
    zbar
    yazi
    superfile
  ];
}

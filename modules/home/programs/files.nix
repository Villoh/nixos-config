{ pkgs, ... }:

{
  home-manager.users.mikel.home.packages = with pkgs; [
    kdePackages.dolphin
    kdePackages.ark
    kdePackages.okular
    onlyoffice-desktopeditors
    qtengine
    fastfetch
    yazi
    superfile
  ];
}

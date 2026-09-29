{ pkgs, ... }:

{
  home-manager.users.mikel.home.packages = with pkgs; [
    kdePackages.dolphin
    kdePackages.plasma-workspace
    kdePackages.ark
    kdePackages.okular
    onlyoffice-desktopeditors
    handy
    wtype
  ];
}

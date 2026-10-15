{ inputs, pkgs, ... }:

{
  home.packages = [
    (pkgs.callPackage ./strata.nix { })
    inputs.arca.packages.${pkgs.stdenv.hostPlatform.system}.default
  ]
  ++ (with pkgs; [
    kdePackages.dolphin
    kdePackages.kio-extras
    kdePackages.kde-cli-tools
    kdePackages.plasma-workspace
    kdePackages.ark
    kdePackages.okular
    dbeaver-bin
    onlyoffice-desktopeditors
    handy
    wtype
  ]);
}

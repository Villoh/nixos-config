{ inputs, pkgs, ... }:

{
  home.packages = [
    (pkgs.callPackage ./strata.nix { })
    (pkgs.callPackage ./wealthfolio.nix { })
    inputs.arca.packages.${pkgs.stdenv.hostPlatform.system}.default
  ]
  ++ (with pkgs; [
    papirus-icon-theme
    tela-icon-theme
    fluent-icon-theme
    kdePackages.dolphin
    kdePackages.kio-extras
    kdePackages.kde-cli-tools
    kdePackages.plasma-workspace
    kdePackages.ark
    kdePackages.okular
    qalculate-qt # standalone calculator (units, currency)
    libqalculate # qalc CLI: optional engine of the DMS Calculator plugin
    dbeaver-bin
    onlyoffice-desktopeditors
    handy
    wtype
  ]);
}

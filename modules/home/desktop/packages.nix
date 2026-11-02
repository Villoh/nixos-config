{ inputs, pkgs, ... }:

{
  home.packages = [
    inputs.strata.packages.${pkgs.stdenv.hostPlatform.system}.strata
    # Registers org.freedesktop.FileManager1 (what the previous in-tree package did).
    inputs.strata.packages.${pkgs.stdenv.hostPlatform.system}.strata.fileManagerService
    pkgs.wealthfolio
    inputs.arca.packages.${pkgs.stdenv.hostPlatform.system}.default
  ]
  ++ (with pkgs; [
    nautilus
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

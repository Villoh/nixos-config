{ inputs, pkgs, ... }:

let
  # rarSupport pulls in non-free UnRAR (allowUnfree is set in modules/nixos/core/nix.nix).
  strata = pkgs.callPackage "${inputs.strata}/package.nix" { rarSupport = true; };
in
{
  home.packages = [
    strata
    # Registers org.freedesktop.FileManager1 (what the previous in-tree package did).
    strata.fileManagerService
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
    hex
    wtype
  ]);
}

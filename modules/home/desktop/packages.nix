{ inputs, pkgs, ... }:

let
  # PENDING: cache. Source build with RAR support, swapped for the prebuilt release meanwhile
  # (no RAR: the official binary omits non-free UnRAR). Its helpers live in
  # modules/nixos/desktop/packages.nix.
  # rarSupport pulls in non-free UnRAR (allowUnfree is set in modules/nixos/core/nix.nix).
  # strata = pkgs.callPackage "${inputs.strata}/package.nix" { rarSupport = true; };
  strata = pkgs.strata-bin;
in
{
  home.packages = [
    strata
    # Registers org.freedesktop.FileManager1 (what the previous in-tree package did).
    strata.fileManagerService
    pkgs.wealthfolio
    # PENDING: cache. Source build, swapped for the prebuilt release meanwhile.
    # inputs.arca.packages.${pkgs.stdenv.hostPlatform.system}.default
    pkgs.arca-bin
  ]
  ++ (with pkgs; [
    nautilus
    papirus-icon-theme
    tela-icon-theme
    fluent-icon-theme
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

{ inputs, pkgs, ... }:

# File chooser: currently served by Strata, with xdg-desktop-portal-gtk as fallback.
# To switch, enable ONE block (portal in extraPortals + its FileChooser line).
# Always keep "gtk" last as a fallback.
#
# The package is the same as in modules/home/desktop/packages.nix, so it is not built twice.
let
  # PENDING: cache. Prebuilt release (no RAR) meanwhile; the source build was
  # pkgs.callPackage "${inputs.strata}/package.nix" { rarSupport = true; }.
  strata = pkgs.strata-bin;
in
{
  xdg.portal = {
    enable = true;
    extraPortals = [
      # pkgs.xdg-desktop-portal-gtk

      # Strata
      strata.fileChooserPortal

      # Dolphin (KDE Qt/KIO dialog, not Dolphin itself)
      # pkgs.kdePackages.xdg-desktop-portal-kde

      # Files / Nautilus (uses Nautilus' own file chooser)
      # pkgs.xdg-desktop-portal-gnome

      # Dux Files: instead of a package here, set programs.dux-files.portal.enable = true
    ];

    config.common."org.freedesktop.impl.portal.FileChooser" = [
      "strata"
      "gtk"
    ]; # Strata
    # config.common."org.freedesktop.impl.portal.FileChooser" = [ "kde" "gtk" ]; # Dolphin
    # config.common."org.freedesktop.impl.portal.FileChooser" = [ "gnome" "gtk" ]; # Files / Nautilus
    # config.common."org.freedesktop.impl.portal.FileChooser" = [ "dfiles" "gtk" ]; # Dux Files
  };
}

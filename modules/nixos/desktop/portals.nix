{ inputs, pkgs, ... }:

# File chooser: currently served by Strata, with xdg-desktop-portal-gtk as fallback.
# To switch, enable ONE block (portal in extraPortals + its FileChooser line).
# Always keep "gtk" last as a fallback.
#
# The callPackage is identical to modules/home/desktop/packages.nix, so it is not built twice.
let
  strata = pkgs.callPackage "${inputs.strata}/package.nix" { rarSupport = true; };
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
    ];

    config.common."org.freedesktop.impl.portal.FileChooser" = [
      "strata"
      "gtk"
    ]; # Strata
    # config.common."org.freedesktop.impl.portal.FileChooser" = [ "kde" "gtk" ]; # Dolphin
    # config.common."org.freedesktop.impl.portal.FileChooser" = [ "gnome" "gtk" ]; # Files / Nautilus
  };
}

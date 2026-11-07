{ ... }:

{
  imports = [
    ./autostart.nix
    ./browsers.nix
    ./dms-plugins.nix
    ./gtk.nix
    ./mime.nix
    ./noctalia.nix
    ./omarchy-themes.nix
    ./packages.nix
    ./qt.nix
    ./hyprland.nix
    # Alternative to the system python3 with PyGObject (modules/nixos/desktop/packages.nix).
    # ./strata-kdeconnect.nix
  ];
}

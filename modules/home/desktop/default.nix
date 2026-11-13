{ ... }:

{
  imports = [
    ./autostart.nix
    ./browsers.nix
    ./dms
    ./gtk.nix
    ./mime.nix
    ./noctalia
    ./packages.nix
    ./qt.nix
    ./zen.nix
    ./hyprland
    # Alternative to the system python3 with PyGObject (modules/nixos/desktop/packages.nix).
    # ./strata-kdeconnect.nix
  ];
}

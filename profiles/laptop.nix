{ ... }:

{
  # Battery state for the shell (DMS battery widget).
  services.upower.enable = true;

  imports = [
    ../modules/nixos/hardware
    ../modules/nixos/hardware/zswap.nix
    ../modules/nixos/desktop
    ../modules/nixos/services
  ];
}

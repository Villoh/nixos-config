{ ... }:

{
  imports = [
    ../modules/nixos/hardware
    ../modules/nixos/hardware/zswap.nix
    ../modules/nixos/desktop
    ../modules/nixos/services
  ];
}

{ ... }:

{
  imports = [
    ../modules/nixos/services/docker.nix
    ../modules/nixos/hardware
    ../modules/nixos/hardware/zram.nix
    ../modules/nixos/desktop
    ../modules/nixos/services
  ];
}

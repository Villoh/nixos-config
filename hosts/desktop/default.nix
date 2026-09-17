{ inputs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./display.nix
    ../../modules/nixos/common.nix
    ../../modules/nixos/browsers.nix
    ../../modules/nixos/desktop/dms-greeter.nix
    ../../modules/nixos/desktop/dms.nix
    ../../modules/nixos/desktop/hyprland.nix
    ../../modules/nixos/zram.nix
    ../../modules/nixos/gaming.nix
    ../../modules/home
    inputs.home-manager.nixosModules.home-manager
  ];

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = { inherit inputs; };
  };
}

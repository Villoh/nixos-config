{ inputs, ... }:

{
  # Generate this host's hardware-configuration.nix on the Zenbook before
  # adding this host to flake.nix. Do not reuse desktop hardware settings.
  imports = [
    ./hardware-configuration.nix
    ../../modules/nixos/common.nix
    ../../modules/nixos/browsers.nix
    ../../modules/nixos/desktop/dms-greeter.nix
    ../../modules/nixos/desktop/dms.nix
    ../../modules/nixos/desktop/hyprland.nix
    ../../modules/nixos/zram.nix
    ../../modules/home
    inputs.home-manager.nixosModules.home-manager
    ./keyboard.nix
  ];

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = { inherit inputs; };
  };
}

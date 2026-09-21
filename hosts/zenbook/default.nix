{ inputs, ... }:

{
  # Generate this host's hardware-configuration.nix on the Zenbook before
  # adding this host to flake.nix. Do not reuse desktop hardware settings.
  imports = [
    ./hardware-configuration.nix
    ../../modules/nixos/core
    ../../profiles/laptop.nix
    ../../users/mikel
    inputs.home-manager.nixosModules.home-manager
    ./keyboard.nix
  ];

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = { inherit inputs; };
  };
}

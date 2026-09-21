{ inputs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./display.nix
    ../../modules/nixos/core
    ../../profiles/desktop.nix
    ../../profiles/gaming.nix
    ../../users/mikel
    inputs.home-manager.nixosModules.home-manager
  ];

  home-manager = {
    # Preserve pre-existing user files when Home Manager first takes ownership.
    backupFileExtension = "bak";
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = { inherit inputs; };
  };
}

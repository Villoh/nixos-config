{ inputs, ... }:

{
  # Generate this host's hardware-configuration.nix on the Zenbook before
  # adding this host to flake.nix. Do not reuse desktop hardware settings.
  imports = [
    ./hardware-configuration.nix
    ../../modules/nixos/core
    # Optional desktop services, selected by this host rather than the profile.
    ../../modules/nixos/services/flatpak.nix
    ../../modules/nixos/services/printing.nix
    ../../profiles/laptop.nix
    ../../users/mikel
    inputs.home-manager.nixosModules.home-manager
    ./keyboard.nix
  ];

  networking.hostName = "nixos-zenbook";
  system.stateVersion = "26.05";

  boot.loader = {
    systemd-boot.enable = true;
    systemd-boot.configurationLimit = 5;
    efi.canTouchEfiVariables = true;
  };

  services.tailscale.enable = true;
  programs.kdeconnect.enable = true;

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = { inherit inputs; };
  };
}

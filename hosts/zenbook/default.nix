{ ... }:

{
  # Generate this host's hardware-configuration.nix on the Zenbook before
  # adding this host to flake.nix. Do not reuse desktop hardware settings.
  imports = [
    ./hardware-configuration.nix
    ../../modules/nixos/core
    # The RTX 3080 moves to a Thunderbolt eGPU; the Arc iGPU drives the desktop.
    ../../modules/nixos/hardware/egpu-nvidia.nix
    # Optional desktop services, selected by this host rather than the profile.
    ../../modules/nixos/services/docker.nix
    ../../modules/nixos/services/flatpak.nix
    ../../modules/nixos/services/printing.nix
    ../../modules/nixos/services/tailscale.nix
    ../../modules/nixos/services/kdeconnect.nix
    ../../profiles/laptop.nix
    ../../users/mikel
    ../../users/mikel/al68.nix
    ../../modules/nixos/home-manager.nix
    ./display.nix
    ./keyboard.nix
  ];

  networking.hostName = "nixos-zenbook";
  system.stateVersion = "26.05";

  boot.loader = {
    systemd-boot.enable = true;
    systemd-boot.configurationLimit = 5;
    efi.canTouchEfiVariables = true;
  };

  users.users.mikel.extraGroups = [ "docker" ];
}

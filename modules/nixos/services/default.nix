{ ... }:

{
  services.tailscale.enable = true;
  services.power-profiles-daemon.enable = true;

  imports = [
    ./flatpak.nix
    ./printing.nix
    ./storage.nix
  ];
}

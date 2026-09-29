{ ... }:

{
  services.tailscale.enable = true;

  imports = [
    ./flatpak.nix
    ./printing.nix
    ./storage.nix
  ];
}

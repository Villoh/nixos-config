{ ... }:

{
  services.power-profiles-daemon.enable = true;

  imports = [
    ./storage.nix
  ];
}

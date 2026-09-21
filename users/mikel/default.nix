{ ... }:

{
  imports = [
    ./home.nix
    ../../modules/home/core
    ../../modules/home/cloud
    ../../modules/home/desktop
    ../../modules/home/development
    ../../modules/home/media
    ../../modules/home/security
    ../../modules/home/shell
    ../../modules/home/terminals
  ];
}

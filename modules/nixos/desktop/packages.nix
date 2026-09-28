{ inputs, pkgs, ... }:

{
  environment.systemPackages = [
    pkgs.usbutils
    pkgs.brave
    inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];
}

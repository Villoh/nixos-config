{ inputs, pkgs, ... }:

{
  environment.systemPackages = [
    pkgs.brave
    inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];
}

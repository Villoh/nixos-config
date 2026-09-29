{ inputs, pkgs, ... }:

{
  boot.plymouth = {
    enable = true;
    theme = "mac-style";
    themePackages = [
      inputs.mac-style-plymouth.packages.${pkgs.stdenv.hostPlatform.system}.default
    ];
  };

  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 5;
  boot.loader.efi.canTouchEfiVariables = true;
}

{ pkgs, ... }:

{
  boot.plymouth = {
    enable = true;
    theme = "owl";
    themePackages = [
      (pkgs.adi1090x-plymouth-themes.override {
        selected_themes = [ "owl" ];
      })
    ];
  };

  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 5;
  boot.loader.efi.canTouchEfiVariables = true;
}

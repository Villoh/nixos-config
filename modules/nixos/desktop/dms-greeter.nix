{ inputs, pkgs, ... }:

{
  services.displayManager.sddm.enable = false;
  services.desktopManager.plasma6.enable = false;
  services.xserver.enable = false;

  services.displayManager.dms-greeter = {
    enable = true;
    package = inputs.dank-greeter.packages.${pkgs.stdenv.hostPlatform.system}.default;
    compositor = {
      name = "hyprland";
      customConfig = ''
        hl.env("DMS_RUN_GREETER", "1")
        hl.config({
          misc = {
            disable_hyprland_logo = true;
          },
        })
      '';
    };
    # Keep greeter stderr in the greetd journal while diagnosing startup.
    logs.save = false;

  };

}

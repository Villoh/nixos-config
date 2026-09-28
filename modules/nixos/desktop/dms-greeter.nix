{ pkgs, ... }:

{
  programs.hyprland.enable = true;
  environment.systemPackages = [ pkgs.bibata-cursors ];

  services.displayManager.dms-greeter = {
    enable = true;
    compositor = {
      name = "hyprland";
      customConfig = ''
        hl.env("DMS_RUN_GREETER", "1")
        hl.env("XCURSOR_THEME", "Bibata-Modern-Classic")
        hl.env("XCURSOR_SIZE", "24")
        hl.env("HYPRCURSOR_THEME", "Bibata-Modern-Classic")
        hl.env("HYPRCURSOR_SIZE", "24")
        hl.config({
          misc = { disable_hyprland_logo = true },
          cursor = { no_hardware_cursors = 1 },
        })
      '';
    };
    configHome = "/home/mikel";
  };
}

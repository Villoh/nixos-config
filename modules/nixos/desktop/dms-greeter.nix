{ pkgs, ... }:

{
  programs.hyprland.enable = true;
  environment.systemPackages = [ pkgs.bibata-cursors ];

  services.displayManager.dms-greeter = {
    enable = true;
    compositor = {
      name = "hyprland";
      customConfig = ''
        env = XCURSOR_THEME,Bibata-Modern-Classic
        env = XCURSOR_SIZE,24
        env = HYPRCURSOR_THEME,Bibata-Modern-Classic
        env = HYPRCURSOR_SIZE,24
        cursor {
          no_hardware_cursors = 1
        }
      '';
    };
    configHome = "/home/mikel";
  };
}

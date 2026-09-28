{ pkgs, ... }:

{
  programs.hyprland.enable = true;
  environment.systemPackages = [ pkgs.bibata-cursors ];

  services.displayManager.dms-greeter = {
    enable = true;
    compositor.name = "hyprland";
    configHome = "/home/mikel";
  };
}

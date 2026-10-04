{ pkgs, ... }:

{
  programs.hyprland.enable = true;
  environment.systemPackages = [ pkgs.bibata-cursors ];

  services.displayManager.dms-greeter = {
    enable = true;
    compositor.name = "hyprland";
    # Login appearance must not depend on a private home directory.
    configHome = null;
  };
}

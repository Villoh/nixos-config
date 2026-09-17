{ pkgs, ... }:

{
  programs.hyprland = {
    enable = true;
    # DankGreeter launches Hyprland directly; UWSM is not used by this greeter.
    withUWSM = false;
    xwayland.enable = true;
  };

  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  };
}

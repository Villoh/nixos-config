_:

{
  # Keep greeter compositor separate from user Hyprland session. Sway avoids
  # Hyprland/Aquamarine shutdown crashes seen on the login transition.
  programs.sway.enable = true;

  services.displayManager.dms-greeter = {
    enable = true;
    compositor.name = "sway";
    configHome = "/home/mikel";
  };
}

{ ... }:

{
  programs.hyprland = {
    enable = true;
    # UWSM manages the logged-in Hyprland session; DankGreeter remains a
    # separate temporary compositor for the login screen.
    withUWSM = true;
    xwayland.enable = true;
  };
}

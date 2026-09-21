{ pkgs, ... }:

{
  home-manager.users.mikel = {
    home.username = "mikel";
    home.homeDirectory = "/home/mikel";
    home.stateVersion = "26.05";

    home.pointerCursor = {
      enable = true;
      package = pkgs.bibata-cursors;
      name = "Bibata-Modern-Classic";
      size = 24;
      gtk.enable = true;
      # Keep the existing chezmoi-managed ~/.Xresources untouched.
      x11.enable = false;
    };
  };
}

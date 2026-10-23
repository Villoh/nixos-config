{ pkgs, ... }:

{
  gtk = {
    enable = true;
    gtk2.enable = false;
    iconTheme = {
      name = "Colloid";
      package = pkgs.colloid-icon-theme;
    };
  };

  # DMS owns these files; GTK's Home Manager module still sets dconf and installs icons.
  xdg.configFile = {
    "gtk-3.0/settings.ini".enable = false;
    "gtk-4.0/settings.ini".enable = false;
  };
}

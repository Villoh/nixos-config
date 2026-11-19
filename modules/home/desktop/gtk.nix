{ pkgs, ... }:

{
  gtk = {
    enable = true;
    gtk2.enable = false;
    iconTheme = {
      name = "Colloid-Dark"; # dconf fallback if DMS iconThemeDark is "System Default"
      package = pkgs.colloid-icon-theme;
    };
    # DMS's "Apply GTK colors" does this by hand; declared so new installs need no click.
    # A user-managed (HM) symlink that imports dank-colors.css counts as opted in.
    gtk3.extraCss = ''@import url("dank-colors.css");'';
    gtk4.extraCss = ''@import url("dank-colors.css");'';
  };

  # dank-colors.css overrides libadwaita color names, which only adw-gtk3 honours (nixos/desktop/dms
  # installs it). DMS flips this to adw-gtk3 in light mode, but only while it is an adw-gtk3 variant.
  dconf.settings."org/gnome/desktop/interface".gtk-theme = "adw-gtk3-dark";

  # DMS owns these files; GTK's Home Manager module still sets dconf and installs icons.
  xdg.configFile = {
    "gtk-3.0/settings.ini".enable = false;
    "gtk-4.0/settings.ini".enable = false;
  };
}

{ pkgs, ... }:

{
  home-manager.users.mikel.home.packages = with pkgs; [
    kdePackages.dolphin
    kdePackages.plasma-workspace
    kdePackages.ark
    kdePackages.okular
    onlyoffice-desktopeditors
    vesktop
    handy
    wtype
  ];

  # App-generated autostarts bypass Nix wrappers and lose their runtime environment.
  home-manager.users.mikel.xdg.configFile = {
    "autostart/Handy.desktop".text = ''
      [Desktop Entry]
      Type=Application
      Version=1.0
      Name=Handy
      Comment=Handystartup script
      Exec=${pkgs.handy}/bin/handy
      StartupNotify=false
      Terminal=false
    '';
    "autostart/vesktop.desktop".text = ''
      [Desktop Entry]
      Type=Application
      Name=Vesktop
      Comment=Vesktop autostart script
      Exec=${pkgs.vesktop}/bin/vesktop --start-minimized
      StartupNotify=false
      Terminal=false
      Icon=vesktop
    '';
  };
}

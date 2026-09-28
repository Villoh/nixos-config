{ config, pkgs, ... }:

{
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
    # Reuse the launcher's FHS wrapper, which provides ICU for Tunnel Agent.
    "autostart/tunnelagent.desktop".text = ''
      [Desktop Entry]
      Type=Application
      Version=1.0
      Name=Tunnel Agent
      Comment=Start Tunnel Agent at login
      Exec=${config.home-manager.users.mikel.xdg.desktopEntries.tunnel-agent.exec} --start-in-tray
      Terminal=false
      X-GNOME-Autostart-enabled=true
    '';
  };
}

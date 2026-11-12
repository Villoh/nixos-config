{
  config,
  lib,
  pkgs,
  ...
}:

let
  # Only the dictation client picked by DICTATION starts at login.
  dictation = config.home.sessionVariables.DICTATION;
in
{
  # App-generated autostarts bypass Nix wrappers and lose their runtime environment.
  xdg.configFile = {
    "autostart/Handy.desktop" = lib.mkIf (dictation == "handy") {
      text = ''
        [Desktop Entry]
        Type=Application
        Version=1.0
        Name=Handy
        Comment=Handystartup script
        Exec=${pkgs.handy}/bin/handy
        StartupNotify=false
        Terminal=false
      '';
    };
    # `hex start` runs it in the background without opening the window.
    "autostart/anomaly.hex.desktop" = lib.mkIf (dictation == "hex") {
      text = ''
        [Desktop Entry]
        Type=Application
        Version=1.0
        Name=Hex
        Comment=Start Hex voice dictation at login
        Exec=${pkgs.hex}/bin/hex start
        StartupNotify=false
        Terminal=false
      '';
    };
    "autostart/zapfast.desktop".text = ''
      [Desktop Entry]
      Type=Application
      Version=1.0
      Name=ZapFast
      Comment=Start ZapFast at login
      # ZapFast only hides if the tray exists at launch; DMS registers it late.
      Exec=${pkgs.runtimeShell} -c "sleep 5 && exec ${lib.getExe pkgs.zapfast} --start-hidden"
      StartupNotify=false
      Terminal=false
    '';
    "autostart/filen-desktop.desktop".text = ''
      [Desktop Entry]
      Type=Application
      Name=Filen Desktop
      Comment=Start Filen Desktop at login
      Exec=${pkgs.filen-desktop}/bin/filen-desktop
      StartupNotify=false
      Terminal=false
    '';
    "autostart/hylki.desktop".text = ''
      [Desktop Entry]
      Type=Application
      Version=1.0
      Name=Hylki
      Comment=Start Hylki hidden at login
      Exec=flatpak run co.hyprlab.Hylki --hidden
      StartupNotify=false
      Terminal=false
    '';
    # Reuse the launcher's FHS wrapper, which provides ICU for Tunnel Agent.
    "autostart/tunnelagent.desktop".text = ''
      [Desktop Entry]
      Type=Application
      Version=1.0
      Name=Tunnel Agent
      Comment=Start Tunnel Agent at login
      Exec=${config.xdg.desktopEntries.tunnel-agent.exec} --start-in-tray
      Terminal=false
      X-GNOME-Autostart-enabled=true
    '';
  };
}

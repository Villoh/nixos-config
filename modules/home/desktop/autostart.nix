{
  config,
  lib,
  pkgs,
  ...
}:

let
  # Only the dictation client picked by DICTATION starts at login.
  dictation = config.home.sessionVariables.DICTATION;

  # Start these after DMS is ready (dms.service is Type=notify and only reports ready once
  # the tray exists) so they do not compete with it for CPU while it loads. Names are the
  # autostart .desktop ids, systemd-escaped (`-` is `\x2d`).
  afterDms = lib.listToAttrs (
    map
      (id: {
        name = "systemd/user/app-${id}@autostart.service.d/after-dms.conf";
        value.text = ''
          [Unit]
          After=dms.service
        '';
      })
      [
        "Handy"
        "anomaly.hex"
        "zapfast"
        "serein"
        "filen\\x2ddesktop"
        "hylki"
        "tunnelagent"
        "org.kde.kdeconnect.daemon"
      ]
  );
in
{
  # App-generated autostarts bypass Nix wrappers and lose their runtime environment.
  xdg.configFile = afterDms // {
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
      # Ordered after dms.service (above), which is ready once the tray exists.
      Exec=${lib.getExe pkgs.zapfast} --start-hidden
      StartupNotify=false
      Terminal=false
    '';
    # shortcut: --start-minimized only asks for a minimize, which Hyprland ignores, so the window
    # may still open; revisit if Serein gets a real start-in-tray on Linux.
    "autostart/serein.desktop".text = ''
      [Desktop Entry]
      Type=Application
      Version=1.0
      Name=Serein
      Comment=Start Serein at login
      Exec=${lib.getExe pkgs.serein-bin} --start-minimized
      StartupNotify=false
      Terminal=false
    '';
    "autostart/filen-desktop.desktop".text = ''
      [Desktop Entry]
      Type=Application
      Name=Filen Desktop
      Comment=Start Filen Desktop at login
      # The home profile one: it is built with Electron 43 (../cloud/packages.nix); the
      # default pkgs.filen-desktop crashes on load with Electron 45.
      Exec=${config.home.path}/bin/filen-desktop
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

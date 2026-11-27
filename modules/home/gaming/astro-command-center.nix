{ pkgs, ... }:

# ASTRO Command Center (MixAmp Pro EQ/presets) has no Linux build. The legacy Win32 MSI
# runs under Wine >= 11.21: earlier versions stub CM_Get_Parent, so the app never sees
# the MixAmp. Do not switch to wineWow64Packages.stable (11.0) or Bottles runners.
# Needs the hidraw udev rule in modules/nixos/hardware/astro-mixamp.nix.
let
  wine = pkgs.wineWow64Packages.unstable;

  msi = pkgs.fetchurl {
    url = "https://update.astrogaming.com/kuiper/AstroCommandCenter.msi";
    hash = "sha256-LkNC/BEXFBtvPWNm2aZK46V2g68gK/rQ6Q864Rg56xk=";
  };

  # The MSI embeds the app icon; pull it out so the launcher matches the installed app.
  icon = pkgs.runCommand "astro-command-center-icon"
    {
      nativeBuildInputs = [
        pkgs.msitools
        pkgs.icoutils
      ];
    }
    ''
      msiinfo extract ${msi} Icon.ProgramIcon.ico > icon.ico
      icotool -x icon.ico
      for f in icon_*.png; do
        size=$(echo "$f" | sed -E 's/.*_([0-9]+)x[0-9]+x[0-9]+\.png/\1/')
        install -Dm644 "$f" "$out/share/icons/hicolor/''${size}x''${size}/apps/astro-command-center.png"
      done
    '';

  astro-command-center = pkgs.writeShellApplication {
    name = "astro-command-center";
    runtimeInputs = [ wine ];
    text = ''
      export WINEPREFIX="''${XDG_DATA_HOME:-$HOME/.local/share}/wineprefixes/astro-command-center"
      export WINEDEBUG=-all

      # XWayland is not scaled here (force_zero_scaling) and the monitors run at 1.5, so Wine's
      # default 96 DPI draws a tiny UI. 144 = 150 %. Idempotent; wineboot creates the prefix.
      wine reg add 'HKCU\Control Panel\Desktop' /v LogPixels /t REG_DWORD /d 144 /f > /dev/null
      exe="$WINEPREFIX/drive_c/Program Files (x86)/Astro Gaming/ASTRO Command Center/ASTRO Command Center.exe"

      # First run: the silent install also starts the app.
      if [ -e "$exe" ]; then
        exec wine "$exe"
      fi
      exec wine msiexec /i ${msi} /qn
    '';
  };
in
{
  home.packages = [
    astro-command-center
    icon
    (pkgs.makeDesktopItem {
      name = "astro-command-center";
      desktopName = "ASTRO Command Center";
      comment = "Configure the ASTRO MixAmp Pro (EQ presets, mic, Stream Port)";
      exec = "astro-command-center";
      icon = "astro-command-center";
      categories = [
        "Audio"
        "Settings"
      ];
    })
  ];
}

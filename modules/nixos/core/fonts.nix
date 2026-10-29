{ pkgs, inputs, ... }:

let
  selawik = pkgs.stdenvNoCC.mkDerivation {
    pname = "selawik";
    version = "1.01";
    src = pkgs.fetchzip {
      url = "https://github.com/microsoft/Selawik/releases/download/1.01/Selawik_Release.zip";
      hash = "sha256-BbjXJ8HFXrRklMOnGXyZIZeQ5Oksda4AqQXHmNqN6AQ=";
      stripRoot = false;
    };
    installPhase = ''
      install -Dm644 *.ttf -t $out/share/fonts/truetype
    '';
    meta = {
      description = "Open-source replacement for Segoe UI";
      homepage = "https://github.com/microsoft/Selawik";
      license = pkgs.lib.licenses.ofl;
      platforms = pkgs.lib.platforms.all;
    };
  };
in
{
  fonts = {
    packages = [
      pkgs.inter
      pkgs.noto-fonts
      selawik
      # Real Tahoma and Tahoma Bold (corefonts only has Tahoma Regular), Segoe UI, Consolas,
      # Lucida Console and the rest of the Windows 11 base fonts.
      inputs.nix-ttf-ms-win11-auto.packages.${pkgs.stdenv.hostPlatform.system}.ttf-ms-win11-auto
    ];

    fontconfig = {
      defaultFonts = {
        sansSerif = [
          "Inter"
          "Noto Sans"
        ];
        serif = [
          "Liberation Serif"
          "Noto Serif"
        ];
        monospace = [
          "Fira Code"
          "Noto Sans Mono"
        ];
      };

      localConf = ''
        <fontconfig>
          <match target="pattern">
            <test name="family" qual="any"><string>Segoe UI Webfont</string></test>
            <edit name="family" mode="assign" binding="same"><string>Selawik</string></edit>
          </match>
        </fontconfig>
      '';
    };
  };
}

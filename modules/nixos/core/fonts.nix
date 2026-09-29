{ pkgs, ... }:

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
      pkgs.corefonts
      pkgs.vista-fonts
      pkgs.noto-fonts
      selawik
      # Optional: add flake input above and pass inputs into this module.
      # It covers corefonts except Andale Mono, plus all vista-fonts families:
      # Arial, Arial Black, Comic Sans MS, Courier New, Georgia, Impact,
      # Times New Roman, Trebuchet MS, Verdana, Webdings, Calibri, Cambria,
      # Candara, Consolas, Constantia, Corbel.
      # inputs.nix-ttf-ms-win11-auto.packages.${pkgs.stdenv.hostPlatform.system}.ttf-ms-win11-auto
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
            <test name="family" qual="any"><string>Segoe UI</string></test>
            <edit name="family" mode="assign" binding="same"><string>Selawik</string></edit>
          </match>
          <match target="pattern">
            <test name="family" qual="any"><string>Segoe UI Variable</string></test>
            <edit name="family" mode="assign" binding="same"><string>Selawik</string></edit>
          </match>
          <match target="pattern">
            <test name="family" qual="any"><string>Segoe UI Webfont</string></test>
            <edit name="family" mode="assign" binding="same"><string>Selawik</string></edit>
          </match>
        </fontconfig>
      '';
    };
  };
}

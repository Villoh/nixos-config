{ pkgs, inputs, ... }:

{
  fonts = {
    packages = [
      pkgs.inter
      pkgs.noto-fonts
      pkgs.selawik
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

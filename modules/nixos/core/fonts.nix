{ pkgs, inputs, ... }:

{
  fonts = {
    packages = [
      pkgs.inter
      pkgs.noto-fonts
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
    };
  };
}

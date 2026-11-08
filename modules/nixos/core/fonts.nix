{ pkgs, inputs, ... }:

{
  fonts = {
    packages = [
      pkgs.inter
      pkgs.fira-code
      pkgs.liberation_ttf
      pkgs.noto-fonts # GTK's UI font (Noto Sans) and the glyph fallback
      # Real Tahoma and Tahoma Bold (corefonts only has Tahoma Regular), Segoe UI, Consolas,
      # Lucida Console and the rest of the Windows 11 base fonts.
      inputs.nix-ttf-ms-win11-auto.packages.${pkgs.stdenv.hostPlatform.system}.ttf-ms-win11-auto
    ];

    # Which real font answers the generic families (sans-serif, serif, monospace) that web
    # pages and apps without their own font ask for. Inter and Fira Code are DMS's own UI
    # defaults, so the rest of the system matches the shell. Terminals (kitty, ghostty) and
    # GTK pin their own fonts and ignore this.
    fontconfig.defaultFonts = {
      sansSerif = [ "Inter" ];
      serif = [ "Liberation Serif" ];
      monospace = [ "Fira Code" ];
    };
  };
}

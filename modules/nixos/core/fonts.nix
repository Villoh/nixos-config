{ pkgs, inputs, ... }:

{
  fonts = {
    packages = [
      pkgs.inter
      pkgs.fira-code
      pkgs.liberation_ttf
      pkgs.nerd-fonts.jetbrains-mono # kitty and ghostty
      pkgs.google-sans-flex # Dux Shell 2.0's UI font
      pkgs.noto-fonts # GTK's UI font (Noto Sans) and the glyph fallback
      # Real Tahoma and Tahoma Bold (corefonts only has Tahoma Regular), Segoe UI, Consolas,
      # Lucida Console and the rest of the Windows 11 base fonts.
      inputs.nix-ttf-ms-win11-auto.packages.${pkgs.stdenv.hostPlatform.system}.ttf-ms-win11-auto
    ];

    # Which real font answers the generic families (sans-serif, serif, monospace) that web
    # pages and apps without their own font ask for. Dux Shell draws its own UI with its
    # bundled fonts (Google Sans Flex, Fira Code), so this only affects everything else.
    # Terminals (kitty, ghostty) and GTK pin their own fonts and ignore it.
    fontconfig.defaultFonts = {
      sansSerif = [ "Inter" ];
      serif = [ "Liberation Serif" ];
      monospace = [ "Fira Code" ];
    };
  };
}

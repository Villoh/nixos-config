{ pkgs, ... }:

let
  # Keep this per-user input-method fix; NixOS provides unwrapped Ghostty as a fallback.
  ghostty = pkgs.symlinkJoin {
    name = "ghostty-with-simple-im";
    meta.mainProgram = "ghostty";
    paths = [ pkgs.ghostty ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram "$out/bin/ghostty" --set GTK_IM_MODULE simple
    '';
  };
in
{
  programs.ghostty = {
    enable = true;
    package = ghostty;
    settings = {
      # DMS generates this theme dynamically through matugen.
      theme = "dankcolors";
      "font-family" = "JetBrainsMono Nerd Font";
      "font-size" = 10;
      "font-codepoint-map" = [
        "U+E1A0-U+E1B6=Herdr Agent Icons Max"
        "U+E1C0-U+E1C5=Herdr Agent Icons Max"
      ];
    };
  };
}

{ ... }:

{
  home-manager.users.mikel.programs.ghostty = {
    enable = true;
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

{ ... }:

{
  home-manager.users.mikel.programs.ghostty = {
    enable = true;
    settings = {
      # DMS generates this theme dynamically through matugen.
      theme = "dankcolors";
      "font-family" = "JetBrainsMono Nerd Font";
      "font-size" = 10;
    };
  };
}

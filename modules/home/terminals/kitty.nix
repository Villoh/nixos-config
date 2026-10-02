{ pkgs, ... }:

{
  home-manager.users.mikel.programs.kitty = {
    enable = true;
    settings = {
      # Use Zsh even when Kitty is launched from an existing Bash session.
      shell = "${pkgs.zsh}/bin/zsh";
      font_family = "JetBrainsMono Nerd Font";
      font_size = 10;
      # Kitty restores last size/maximized state from ~/.cache/kitty/main.json.
      remember_window_size = false;
    };
    extraConfig = ''
      symbol_map U+E1A0-U+E1B6 Herdr Agent Icons Max
      symbol_map U+E1C0-U+E1C5 Herdr Agent Icons Max

      # DMS generates these files dynamically with Matugen.
      include dank-tabs.conf
      include dank-theme.conf
    '';
  };
}

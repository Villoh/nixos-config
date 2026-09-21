{ pkgs, ... }:

{
  home-manager.users.mikel.programs.kitty = {
    enable = true;
    settings = {
      # Use Zsh even when Kitty is launched from an existing Bash session.
      shell = "${pkgs.zsh}/bin/zsh";
      font_family = "JetBrainsMono Nerd Font";
      font_size = 10;
    };
    extraConfig = ''
      # DMS generates these files dynamically with Matugen.
      include dank-tabs.conf
      include dank-theme.conf
    '';
  };
}

{ pkgs, ... }:

{
  home-manager.users.mikel = {
    home.packages = [ pkgs.concord-tui ];

    xdg.configFile."concord/keymap.toml".text = ''
      [keymap]
      VoiceMute = { keys = [ "<leader>vm", "<A-m>" ] }
      VoiceDeafen = { keys = [ "<leader>vd", "<A-d>" ] }
    '';
  };
}

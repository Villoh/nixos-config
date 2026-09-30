{ inputs, pkgs, ... }:

{
  home-manager.users.mikel = {
    home.packages = with pkgs; [
      concord-tui
      vesktop
      inputs.zapfast.packages.${pkgs.stdenv.hostPlatform.system}.zapfast
    ];

    xdg.configFile."concord/keymap.toml".text = ''
      [keymap]
      VoiceMute = { keys = [ "<leader>vm", "<A-m>" ] }
      VoiceDeafen = { keys = [ "<leader>vd", "<A-d>" ] }
    '';
  };
}

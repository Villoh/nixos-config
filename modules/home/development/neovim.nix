{ inputs, pkgs, ... }:

{
  programs.neovim = {
    enable = true;
    plugins = [
      {
        plugin = pkgs.vimUtils.buildVimPlugin {
          pname = "base46";
          version = "unstable";
          nvimRequireCheck = "base46";
          src = inputs.base46;
        };
      }
    ];
  };
}

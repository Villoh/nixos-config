{ inputs, pkgs, ... }:

{
  home-manager.users.mikel = {
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

    home.packages = with pkgs; [
      zed-editor
      herdr
      rustup
      nodejs_24
      deno
      mise
      jdk
      dotnet-sdk_10
      python3
      uv
      pnpm
    ];
  };
}

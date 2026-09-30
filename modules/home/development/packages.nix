{ inputs, pkgs, ... }:

{
  home-manager.users.mikel = {
    home.packages = with pkgs; [
      zed-editor
      mysql84.client
      usql
      acli
      claude-code
      codex
      nchat
      devin-cli
      herdr
      rustup
      nodejs_24
      deno
      mise
      jdk
      maven
      dotnet-sdk_10
      python3
      uv
      pnpm
    ];
  };
}

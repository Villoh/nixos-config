{ pkgs, ... }:

{
  home-manager.users.mikel = {
    home.packages = with pkgs; [
      zed-editor
      mysql84.client
      usql
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

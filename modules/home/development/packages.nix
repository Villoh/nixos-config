{ pkgs, ... }:

{
  home-manager.users.mikel.home.packages = with pkgs; [
    zed-editor
    herdr
    rustup
    nodejs_24
    deno
    mise
    jdk
    dotnet-sdk
    python3
    uv
    pnpm
  ];
}

{ pkgs, ... }:

{
  home-manager.users.mikel.home.packages = with pkgs; [
    zed-editor
    git
    gh
    chezmoi
    gum
    rtk
    ripgrep
    fd
    fzf
    zoxide
    eza
    bat
    jq
    yq
    sd
    dust
    procs
    btop
    tree
    tealdeer
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

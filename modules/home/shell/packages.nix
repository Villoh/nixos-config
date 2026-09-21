{ pkgs, ... }:

{
  home-manager.users.mikel.home.packages = with pkgs; [
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
    fastfetch
  ];
}

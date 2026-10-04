{ pkgs, ... }:

{
  home.packages = with pkgs; [
    usbutils
    evtest
    wl-clipboard
    git
    git-lfs
    nix-index
    gh
    chezmoi
    gum
    rtk
    ripgrep
    fd
    fzf
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

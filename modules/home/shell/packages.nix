{ pkgs, ... }:

{
  home-manager.users.mikel.home.packages = with pkgs; [
    usbutils
    evtest
    wl-clipboard
    git
    git-lfs
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
    nh
  ];
}

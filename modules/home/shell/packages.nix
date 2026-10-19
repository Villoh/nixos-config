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
    libarchive # bsdtar: opens .rar (RAR5 too) and .zip; imperivm-resurrected tools/wrap-map.js needs it
    tealdeer
    fastfetch
  ];
}

{ pkgs, ... }:

{
  home.packages = with pkgs; [
    usbutils
    lsof
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
    trash-cli # trash-put/trash-list/trash-restore: freedesktop trash, same one Dolphin uses
    libarchive # bsdtar: opens .rar (RAR5 too) and .zip; imperivm-resurrected tools/wrap-map.js needs it
    tealdeer
    fastfetch
  ];
}

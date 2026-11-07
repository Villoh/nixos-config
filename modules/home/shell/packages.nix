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
    glab # GitLab CLI, the gh equivalent for gitlab.com
    tea # Gitea/Forgejo CLI, works against codeberg.org
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

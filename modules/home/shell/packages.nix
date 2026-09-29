{ pkgs, ... }:

let
  padpoll = pkgs.stdenvNoCC.mkDerivation {
    pname = "padpoll";
    version = "1.1.0";
    src = pkgs.fetchurl {
      url = "https://github.com/PabloStarOk/padpoll/releases/download/v1.1.0/padpoll-linux.tar.gz";
      hash = "sha256-0ev13g5Q8L+n8j/v87fx/O4Kkd1RQmzI5YJ5QbI+xXE=";
    };
    nativeBuildInputs = [ pkgs.autoPatchelfHook ];
    buildInputs = [ pkgs.stdenv.cc.cc.lib ];
    dontUnpack = true;
    installPhase = ''
      install -d "$out/bin"
      tar -xzf "$src" -C "$out/bin" padpoll
      chmod 755 "$out/bin/padpoll"
    '';
  };
in
{
  home-manager.users.mikel.home.packages = with pkgs; [
    usbutils
    evtest
    padpoll
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

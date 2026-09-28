{ inputs, pkgs, ... }:

let
  zen-browser = pkgs.wrapFirefox (
    inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.zen-browser-unwrapped.overrideAttrs
      (old: {
        passthru = (old.passthru or { }) // {
          # wrapFirefox checks withFFmpeg; the flake's ffmpegSupport flag is ignored.
          withFFmpeg = true;
        };
      })
  ) { pname = "zen-browser"; };

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
  environment.systemPackages = [
    pkgs.usbutils
    pkgs.evtest
    padpoll
    pkgs.brave
    zen-browser
  ];
}

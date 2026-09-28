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
in
{
  environment.systemPackages = [
    pkgs.usbutils
    pkgs.brave
    zen-browser
  ];
}

# Android emulator (AVD) shell: `nix develop .#android`.
# Creates two AVDs on first use (kept in $XDG_DATA_HOME/android, not in the repo):
#   play  Google Play image, for apps/games that need Play Store/Play Integrity.
#   root  Google APIs image, `adb root` works (no Play Store).
# arm64 images are not an option: the emulator refuses them on x86_64 hosts. The
# x86_64 images already run arm64 apps through Google's built-in translation.
# Run with: emulator -avd play -gpu host
{ pkgs }:

let
  sdk = pkgs.androidenv.composeAndroidPackages {
    platformVersions = [ "35" ];
    systemImageTypes = [
      "google_apis"
      "google_apis_playstore"
    ];
    abiVersions = [ "x86_64" ];
    includeEmulator = true;
    includeSystemImages = true;
  };
in
pkgs.mkShell {
  packages = [
    sdk.androidsdk
    pkgs.android-tools
    pkgs.jdk21
  ];

  ANDROID_SDK_ROOT = "${sdk.androidsdk}/libexec/android-sdk";

  shellHook = ''
    export ANDROID_USER_HOME="''${XDG_DATA_HOME:-$HOME/.local/share}/android"
    export ANDROID_AVD_HOME="$ANDROID_USER_HOME/avd"
    mkdir -p "$ANDROID_AVD_HOME"

    mk_avd() { # name, image tag
      [ -d "$ANDROID_AVD_HOME/$1.avd" ] && return
      echo no | avdmanager create avd -n "$1" -d pixel_8 \
        -k "system-images;android-35;$2;x86_64" >/dev/null 2>&1
      printf '%s\n' hw.ramSize=6144 hw.cpu.ncore=8 disk.dataPartition.size=16G \
        hw.keyboard=yes >> "$ANDROID_AVD_HOME/$1.avd/config.ini"
    }
    mk_avd play google_apis_playstore
    mk_avd root google_apis
  '';
}

{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  makeWrapper,
  alsa-lib,
  cairo,
  ffmpeg-headless,
  fontconfig,
  gdk-pixbuf,
  glib,
  gtk-layer-shell,
  gtk3,
  harfbuzz,
  libappindicator-gtk3,
  libepoxy,
  libglvnd,
  libsecret,
  libx11,
  nodejs,
  pango,
  yt-dlp,
  nix-update-script,
}:

# The minimal release: a static Go binary that dlopens GTK, the tray and ALSA at run time.
# ffmpeg, yt-dlp and Node come from nixpkgs instead of the full build's bundled copies (about
# 56 MiB of ffmpeg, yt-dlp and Python), so yt-dlp follows nixpkgs; upstream says an old
# yt-dlp makes playback slow or fail.
# The tarball layout is kept under lib/meiro: the app may look for its icons beside itself.
# Discord Rich Presence needs nothing here: it dials $XDG_RUNTIME_DIR/discord-ipc-N, including
# the .flatpak/<id>/xdg-run copies, and this build has no sandbox.
stdenv.mkDerivation (finalAttrs: {
  pname = "meiro";
  version = "0.6.2";

  src = fetchurl {
    url = "https://github.com/elianiva/meiro/releases/download/desktop-v${finalAttrs.version}/meiro-${finalAttrs.version}-linux-amd64-minimal.tar.gz";
    hash = "sha256-gEjvWgeH8IFAKIu8JFgj/LYxL8FAgIJzuI7XIDneghw=";
  };

  sourceRoot = ".";

  nativeBuildInputs = [
    autoPatchelfHook
    makeWrapper
  ];
  buildInputs = [ stdenv.cc.cc.lib ];

  installPhase = ''
    runHook preInstall
    mkdir -p $out/lib/meiro
    cp -a meiro bin licenses *.png THIRD-PARTY-NOTICES.md $out/lib/meiro/
    makeWrapper $out/lib/meiro/meiro $out/bin/meiro \
      --prefix PATH : ${
        lib.makeBinPath [
          ffmpeg-headless
          nodejs
          yt-dlp
        ]
      } \
      --prefix LD_LIBRARY_PATH : ${
        lib.makeLibraryPath [
          alsa-lib
          cairo
          fontconfig
          gdk-pixbuf
          glib
          gtk-layer-shell
          gtk3
          harfbuzz
          libappindicator-gtk3
          libepoxy
          libglvnd
          libsecret
          libx11
          pango
        ]
      }
    install -Dm644 meiro.desktop $out/share/applications/meiro.desktop
    install -Dm644 meiro.png $out/share/icons/hicolor/512x512/apps/meiro.png
    runHook postInstall
  '';

  # Tags are desktop-v<version>; the desktop-minimal-v<version> ones would match first.
  passthru.updateScript = nix-update-script {
    extraArgs = [
      "--version-regex"
      "desktop-v(.*)"
    ];
  };

  meta = {
    description = "Lightweight desktop music player for YouTube Music";
    homepage = "https://github.com/elianiva/meiro";
    license = lib.licenses.gpl3Only;
    platforms = [ "x86_64-linux" ];
    mainProgram = "meiro";
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
})

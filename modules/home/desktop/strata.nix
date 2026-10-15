{
  lib,
  rustPlatform,
  fetchFromGitHub,
  pkg-config,
  wrapGAppsHook4,
  glib,
  gtk4,
  gtksourceview5,
  poppler,
  cairo,
  pango,
  gdk-pixbuf,
  fontconfig,
  gst_all_1,
  bubblewrap,
  ffmpeg,
  ffmpegthumbnailer,
  imagemagick,
  squashfsTools,
}:

# strata is not in nixpkgs and upstream ships no flake, so build it from source.
rustPlatform.buildRustPackage (finalAttrs: {
  pname = "strata";
  version = "0.21.0";

  src = fetchFromGitHub {
    owner = "lgse";
    repo = "strata";
    tag = "v${finalAttrs.version}";
    hash = "sha256-RSTEgtfDYYGxXef1J22NMGpmgjObg3T6APZqfSyfNPY=";
  };

  cargoLock.lockFile = "${finalAttrs.src}/Cargo.lock";

  # build.rs would otherwise shell out to git.
  env.STRATA_BUILD_COMMIT = "v${finalAttrs.version}";

  nativeBuildInputs = [
    pkg-config
    wrapGAppsHook4
    glib # glib-compile-resources
  ];

  buildInputs = [
    glib
    gtk4
    gtksourceview5
    poppler
    cairo
    pango
    gdk-pixbuf
    fontconfig
    gst_all_1.gstreamer
    gst_all_1.gst-plugins-base
    gst_all_1.gst-plugins-good
    gst_all_1.gst-libav
  ];

  # ponytail: tests need a display/portal/bwrap; skip, add when sandboxed GUI tests are wanted.
  doCheck = false;

  postInstall = ''
    install -Dm644 data/io.github.lgse.Strata.desktop \
      $out/share/applications/io.github.lgse.Strata.desktop
    install -Dm644 data/icons/scalable/apps/io.github.lgse.Strata.svg \
      $out/share/icons/hicolor/scalable/apps/io.github.lgse.Strata.svg
    install -Dm644 data/io.github.lgse.Strata.FileManager1.service \
      $out/share/dbus-1/services/io.github.lgse.Strata.FileManager1.service
    substituteInPlace \
      $out/share/dbus-1/services/io.github.lgse.Strata.FileManager1.service \
      --replace-fail "Exec=/usr/bin/strata" "Exec=$out/bin/strata"
  '';

  preFixup = ''
    gappsWrapperArgs+=(--prefix PATH : ${
      lib.makeBinPath [
        bubblewrap
        ffmpeg
        ffmpegthumbnailer
        imagemagick
        squashfsTools
      ]
    })
  '';

  meta = {
    description = "Fast, keyboard-first file manager for Linux";
    homepage = "https://github.com/lgse/strata";
    license = lib.licenses.mit;
    mainProgram = "strata";
    platforms = lib.platforms.linux;
  };
})

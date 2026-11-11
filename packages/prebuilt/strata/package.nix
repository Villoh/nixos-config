{
  lib,
  stdenv,
  fetchurl,
  runCommand,
  autoPatchelfHook,
  wrapGAppsHook4,
  glib,
  gtk4,
  gtksourceview5,
  pango,
  cairo,
  graphene,
  poppler,
  fontconfig,
  gdk-pixbuf,
  librsvg,
  adwaita-icon-theme,
  gst_all_1,
  bubblewrap,
  coreutils,
  ffmpeg,
  ffmpegthumbnailer,
  imagemagick,
  libraw,
  squashfsTools,
  util-linux,
  xdg-utils,
  nix-update-script,
}:

# TEMPORARY prebuilt release of Strata, WITHOUT non-free UnRAR (the official binary omits it;
# the flake build with rarSupport = true is the only way to get RAR).
# The release is built for Arch, not for Nix, so it differs from the flake build in ways that
# are patched here where the source allows it and are known gaps where it does not:
# - Sandbox paths are compile-time defaults but overridable at launch: set below.
# - The in-app updater and runtime integrations are compile-time switches and stay on; the
#   install-source marker below tells Strata a package manager owns the install.
# - STRATA_TRUSTED_COMMAND_PATH is compile-time only and empty in the release: helpers are
#   only found under /usr/bin, /run/current-system/sw/bin and similar, NOT in the per-user
#   profile or the Nix store, so ffmpeg, ffmpegthumbnailer, imagemagick, bubblewrap and the
#   rest have to be in environment.systemPackages for previews and thumbnails to work.
let
  helpers = [
    ffmpeg
    ffmpegthumbnailer
    imagemagick
    libraw
    squashfsTools
    util-linux
    coreutils
    fontconfig
  ];
  # Service files that point at the finished package, so a configuration enables each
  # integration deliberately (same shape as upstream's package.nix).
  integrationFiles =
    name: strata: files:
    runCommand "strata-${name}" { strata = lib.getExe strata; } (
      lib.concatMapStrings (
        { source, target }:
        ''
          install -Dm644 ${source} "$out/${target}"
          substituteInPlace "$out/${target}" \
            --replace-quiet /usr/bin/strata "$strata" \
            --replace-quiet @STRATA_EXECUTABLE@ "$strata"
        ''
      ) files
    );
in
stdenv.mkDerivation (finalAttrs: {
  pname = "strata";
  version = "1.2.1";

  src = fetchurl {
    url = "https://github.com/lgse/strata/releases/download/v${finalAttrs.version}/strata-${finalAttrs.version}-x86_64-unknown-linux-gnu.tar.gz";
    hash = "sha256-pjcQzmJgeOzBBxBSI2gBeaRDe4y5+8401049QsgDMNA=";
  };

  sourceRoot = "strata-${finalAttrs.version}-x86_64-unknown-linux-gnu";

  nativeBuildInputs = [
    autoPatchelfHook
    wrapGAppsHook4
    glib
  ];
  buildInputs = [
    stdenv.cc.cc.lib
    cairo
    fontconfig
    gdk-pixbuf
    glib
    graphene
    gtk4
    gtksourceview5
    pango
    poppler
    librsvg
    adwaita-icon-theme
    gst_all_1.gstreamer
    gst_all_1.gst-plugins-base
    gst_all_1.gst-plugins-good
    gst_all_1.gst-libav
  ];

  installPhase = ''
    runHook preInstall
    install -Dm755 strata $out/bin/strata
    install -Dm644 io.github.lgse.Strata.desktop $out/share/applications/io.github.lgse.Strata.desktop
    substituteInPlace $out/share/applications/io.github.lgse.Strata.desktop \
      --replace-fail 'Exec=strata' "Exec=$out/bin/strata"
    install -Dm644 io.github.lgse.Strata.svg \
      $out/share/icons/hicolor/scalable/apps/io.github.lgse.Strata.svg
    install -Dm644 io.github.lgse.Strata.FileManager1.service \
      $out/share/strata/io.github.lgse.Strata.FileManager1.service
    install -Dm644 portal/strata.portal $out/share/strata/portal/strata.portal
    install -Dm644 portal/org.freedesktop.impl.portal.desktop.strata.service.in \
      $out/share/strata/portal/org.freedesktop.impl.portal.desktop.strata.service.in
    # Marker the nix build ships: tells Strata a package manager owns this install.
    install -Dm644 /dev/stdin $out/share/strata/install-source.toml <<'EOF'
    manager = "Nix"
    package = "strata"
    EOF
    install -Dm644 LICENSE $out/share/licenses/strata/LICENSE
    install -Dm644 THIRD_PARTY_LICENSES.md $out/share/licenses/strata/THIRD_PARTY_LICENSES.md
    runHook postInstall
  '';

  preFixup = ''
    gappsWrapperArgs+=(
      --prefix PATH : ${
        lib.makeBinPath (
          helpers
          ++ [
            bubblewrap
            xdg-utils
          ]
        )
      }
      --set STRATA_SANDBOX_PATH ${lib.makeBinPath helpers}
      --set STRATA_SANDBOX_ROOT /nix/store
      --set STRATA_SANDBOX_PRLIMIT ${lib.getBin util-linux}/bin/prlimit
      --set STRATA_SANDBOX_GDK_PIXBUF_MODULE_FILE ${librsvg}/lib/gdk-pixbuf-2.0/2.10.0/loaders.cache
    )
  '';

  passthru = {
    fileChooserPortal = integrationFiles "file-chooser-portal" finalAttrs.finalPackage [
      {
        source = "${finalAttrs.finalPackage}/share/strata/portal/strata.portal";
        target = "share/xdg-desktop-portal/portals/strata.portal";
      }
      {
        source = "${finalAttrs.finalPackage}/share/strata/portal/org.freedesktop.impl.portal.desktop.strata.service.in";
        target = "share/dbus-1/services/org.freedesktop.impl.portal.desktop.strata.service";
      }
    ];
    fileManagerService = integrationFiles "file-manager-service" finalAttrs.finalPackage [
      {
        source = "${finalAttrs.finalPackage}/share/strata/io.github.lgse.Strata.FileManager1.service";
        target = "share/dbus-1/services/io.github.lgse.Strata.FileManager1.service";
      }
    ];
    updateScript = nix-update-script { };
  };

  meta = {
    description = "GTK4 file manager (prebuilt release, no UnRAR)";
    homepage = "https://github.com/lgse/strata";
    license = lib.licenses.mit;
    platforms = [ "x86_64-linux" ];
    mainProgram = "strata";
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
})

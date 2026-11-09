{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  wrapGAppsHook4,
  zstd,
  alsa-lib,
  bubblewrap,
  fontconfig,
  glib,
  glib-networking,
  gsettings-desktop-schemas,
  gst_all_1,
  gtk4,
  libglvnd,
  libpulseaudio,
  libsoup_3,
  libx11,
  libxcursor,
  libxi,
  libxkbcommon,
  libxrandr,
  pipewire,
  vulkan-loader,
  wayland,
  webkitgtk_6_0,
  xdg-dbus-proxy,
  nix-update-script,
}:

# The nightly channel's Arch package (a plain tar.zst), used as an archive: the AppImage would
# need an FHS env. Upstream only publishes nightlies (all pre-releases). Dependencies and the
# wrapper mirror packaging/nix/package.nix in the Serein repo.
stdenv.mkDerivation (finalAttrs: {
  pname = "serein";
  version = "1.0.0-nightly.20261108.82";

  src = fetchurl {
    # The Arch file name spells the version "1.0.0pre.nightly.<date>.<n>".
    url = "https://github.com/ViceVerse-cz/Serein/releases/download/v${finalAttrs.version}/serein-v${finalAttrs.version}-Linux-arch-serein-${
      lib.replaceStrings [ "-" ] [ "pre." ] finalAttrs.version
    }-1-x86_64.pkg.tar.zst";
    hash = "sha256-7FrKjw2U3+vafc8zar7yck5qvJJkabrbCh3qGoAFKvs=";
  };

  sourceRoot = ".";

  nativeBuildInputs = [
    autoPatchelfHook
    wrapGAppsHook4
    zstd
  ];
  buildInputs = [
    stdenv.cc.cc.lib
    alsa-lib
    glib
    glib-networking
    gsettings-desktop-schemas
    gst_all_1.gst-plugins-base
    gst_all_1.gstreamer
    gtk4
    libpulseaudio
    libsoup_3
    webkitgtk_6_0
  ];
  # GPU and windowing libraries are dlopen'd at run time.
  runtimeDependencies = [
    fontconfig
    libglvnd
    libx11
    libxcursor
    libxi
    libxkbcommon
    libxrandr
    vulkan-loader
    wayland
  ];

  installPhase = ''
    runHook preInstall
    install -Dm755 usr/bin/serein $out/bin/serein
    # The portal matches the app ID to this entry, so it points at the store path.
    install -Dm644 usr/share/applications/cz.viceverse.serein.desktop -t $out/share/applications
    substituteInPlace $out/share/applications/cz.viceverse.serein.desktop \
      --replace-fail "Exec=serein" "Exec=$out/bin/serein"
    mkdir -p $out/share/icons $out/share/doc
    cp -R usr/share/icons/hicolor $out/share/icons/
    cp -R usr/share/doc/serein $out/share/doc/
    runHook postInstall
  '';

  # WebKit's sandbox needs bwrap and xdg-dbus-proxy; video and screen capture need the
  # GStreamer plugins. NixOS keeps the GPU driver's libraries in /run/opengl-driver.
  preFixup = ''
    gappsWrapperArgs+=(
      --prefix PATH : "${lib.makeBinPath [ bubblewrap xdg-dbus-proxy ]}"
      --prefix GST_PLUGIN_SYSTEM_PATH_1_0 : "${
        lib.makeSearchPathOutput "lib" "lib/gstreamer-1.0" (
          with gst_all_1;
          [
            gst-plugins-base
            gst-plugins-good
            gst-plugins-bad
            gst-libav
            gstreamer
            pipewire
          ]
        )
      }"
      --suffix LD_LIBRARY_PATH : /run/opengl-driver/lib
    )
  '';

  passthru.updateScript = nix-update-script { extraArgs = [ "--version=unstable" ]; };

  meta = {
    description = "Native Discord client written in Rust (egui/wgpu), nightly";
    homepage = "https://github.com/ViceVerse-cz/Serein";
    license = with lib.licenses; [
      mit
      asl20
    ];
    platforms = [ "x86_64-linux" ];
    mainProgram = "serein";
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
})

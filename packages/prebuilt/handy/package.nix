{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  dpkg,
  wrapGAppsHook3,
  alsa-lib,
  alsa-plugins,
  glib,
  glib-networking,
  gst_all_1,
  gtk-layer-shell,
  gtk3,
  libayatana-appindicator,
  libsoup_3,
  libx11,
  libxtst,
  openblas,
  openssl,
  pipewire,
  symlinkJoin,
  vulkan-loader,
  webkitgtk_4_1,
  nix-update-script,
}:

let
  alsaPluginDirectory = symlinkJoin {
    name = "handy-alsa-plugins";
    paths = [
      "${pipewire}/lib/alsa-lib"
      "${alsa-plugins}/lib/alsa-lib"
    ];
  };
in
stdenv.mkDerivation (finalAttrs: {
  pname = "handy";
  version = "0.10.0";

  src = fetchurl {
    url = "https://github.com/cjpais/Handy/releases/download/v${finalAttrs.version}/Handy_${finalAttrs.version}_amd64.deb";
    hash = "sha256-zZHw60RaGyCg7XORp3yxF00eXIPRaWSR4SKNE+I2RoQ=";
  };

  nativeBuildInputs = [
    autoPatchelfHook
    dpkg
    wrapGAppsHook3
  ];
  buildInputs = [
    stdenv.cc.cc.lib
    alsa-lib
    glib
    glib-networking
    gtk-layer-shell
    gtk3
    libsoup_3
    libx11
    libxtst
    openblas
    openssl
    vulkan-loader
    webkitgtk_4_1
  ]
  ++ (with gst_all_1; [
    gstreamer
    gst-plugins-base
    gst-plugins-good
    gst-plugins-bad
    gst-plugins-ugly
  ]);
  # The tray icon is loaded with dlopen.
  runtimeDependencies = [ libayatana-appindicator ];

  unpackPhase = "dpkg-deb -x $src .";
  sourceRoot = ".";

  installPhase = ''
    runHook preInstall
    mkdir -p $out
    cp -a usr/bin usr/lib usr/share $out/
    runHook postInstall
  '';

  # No WEBKIT_DISABLE_DMABUF_RENDERER here, unlike nixpkgs' wrapper: it makes WebKitGTK 2.54
  # draw only the damaged regions. Handy 0.10 sets WEBKIT_DMABUF_RENDERER_FORCE_SHM itself.
  preFixup = ''
    gappsWrapperArgs+=(--set ALSA_PLUGIN_DIR "${alsaPluginDirectory}")
  '';

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "Offline speech-to-text dictation app";
    homepage = "https://github.com/cjpais/Handy";
    platforms = [ "x86_64-linux" ];
    mainProgram = "handy";
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
})

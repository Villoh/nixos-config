{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  makeWrapper,
  zstd,
  alsa-lib,
  fontconfig,
  freetype,
  glib,
  libdrm,
  libglvnd,
  libgbm,
  libpulseaudio,
  libva,
  libx11,
  libxcb,
  libxcomposite,
  libxcursor,
  libxdamage,
  libxext,
  libxfixes,
  libxi,
  libxkbcommon,
  libxrandr,
  openssl,
  pipewire,
  wayland,
  nix-update-script,
}:

# The Arch package (a plain tar.zst), used as an archive: the AppImage would need an FHS env.
stdenv.mkDerivation (finalAttrs: {
  pname = "yapfast";
  version = "0.3.0";

  src = fetchurl {
    url = "https://github.com/yapfast/yapfast/releases/download/v${finalAttrs.version}/yapfast-${finalAttrs.version}-1-x86_64.pkg.tar.zst";
    hash = "sha256-CegeJRYKJiXVojxAs9lLxxJvjbuPBxS0MrsMYsOnORQ=";
  };

  sourceRoot = ".";

  nativeBuildInputs = [
    autoPatchelfHook
    makeWrapper
    zstd
  ];
  buildInputs = [
    stdenv.cc.cc.lib
    fontconfig
    glib
    libpulseaudio
  ];
  # GPU, windowing, audio and screen capture libraries are dlopen'd at run time.
  runtimeDependencies = [
    alsa-lib
    fontconfig
    freetype
    libdrm
    libglvnd
    libgbm
    libva
    libx11
    libxcb
    libxcomposite
    libxcursor
    libxdamage
    libxext
    libxfixes
    libxi
    libxkbcommon
    libxrandr
    openssl
    pipewire
    wayland
  ];

  installPhase = ''
    runHook preInstall
    install -Dm755 usr/bin/yapfast $out/bin/yapfast
    install -Dm644 usr/share/applications/io.github.yapfast.Yapfast.desktop -t $out/share/applications
    install -Dm644 usr/share/icons/hicolor/scalable/apps/io.github.yapfast.Yapfast.svg -t $out/share/icons/hicolor/scalable/apps
    # NixOS keeps the GPU driver's libraries in /run/opengl-driver.
    wrapProgram $out/bin/yapfast --suffix LD_LIBRARY_PATH : /run/opengl-driver/lib
    runHook postInstall
  '';

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "Native Discord client that stays light on memory";
    homepage = "https://github.com/yapfast/yapfast";
    license = lib.licenses.gpl3Plus;
    platforms = [ "x86_64-linux" ];
    mainProgram = "yapfast";
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
})

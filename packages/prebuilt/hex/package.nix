{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  makeWrapper,
  dpkg,
  alsa-lib,
  alsa-plugins,
  curl,
  ffmpeg-headless,
  fontconfig,
  libva,
  libxkbcommon,
  openblas,
  openssl,
  pipewire,
  symlinkJoin,
  vulkan-loader,
  wayland,
  wl-clipboard,
  wtype,
  nix-update-script,
}:

let
  alsaPluginDir = symlinkJoin {
    name = "hex-alsa-plugins";
    paths = [
      "${pipewire}/lib/alsa-lib"
      "${alsa-plugins}/lib/alsa-lib"
    ];
  };
in
stdenv.mkDerivation (finalAttrs: {
  pname = "hex";
  version = "3.4.0";

  src = fetchurl {
    url = "https://github.com/anomalyco/hex/releases/download/v${finalAttrs.version}/hex-${finalAttrs.version}-linux-x64.deb";
    hash = "sha256-hibrpP9q/4cQYx5ex9mnFvMDBs/yaq2fG6ELLRcHp/c=";
  };

  nativeBuildInputs = [
    autoPatchelfHook
    dpkg
    makeWrapper
  ];
  buildInputs = [
    stdenv.cc.cc.lib
    alsa-lib
    libxkbcommon
    openssl
    vulkan-loader
  ];
  # Same run-time libraries as the source build's wrapper: the window and GPU stack, and
  # PipeWire and VA-API, which Annotate dlopens.
  runtimeDependencies = [
    fontconfig
    libva
    openblas
    pipewire
    vulkan-loader
    wayland
  ];

  unpackPhase = "dpkg-deb -x $src .";
  sourceRoot = ".";

  installPhase = ''
    runHook preInstall
    install -Dm755 usr/bin/hex $out/bin/hex
    install -Dm644 usr/share/applications/anomaly.hex.desktop -t $out/share/applications
    mkdir -p $out/share
    cp -R usr/share/icons $out/share/icons
    substituteInPlace $out/share/applications/anomaly.hex.desktop --replace-fail /usr/bin/hex $out/bin/hex
    wrapProgram $out/bin/hex \
      --prefix PATH : ${
        lib.makeBinPath [
          curl
          ffmpeg-headless
          wl-clipboard
          wtype
        ]
      } \
      --set ALSA_PLUGIN_DIR ${alsaPluginDir}
    runHook postInstall
  '';

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "Local voice dictation";
    homepage = "https://github.com/anomalyco/hex";
    platforms = [ "x86_64-linux" ];
    mainProgram = "hex";
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
})

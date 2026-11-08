{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  makeWrapper,
  alsa-lib,
  fontconfig,
  freetype,
  libglvnd,
  libx11,
  libxcb,
  libxcursor,
  libxi,
  libxkbcommon,
  libxrandr,
  vulkan-loader,
  wayland,
  wl-clipboard,
  xclip,
  nix-update-script,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "sheprd";
  version = "20261106.1";

  src = fetchurl {
    url = "https://github.com/sheprd-labs/sheprd/releases/download/v${finalAttrs.version}/Sheprd-${finalAttrs.version}-x86_64-unknown-linux-gnu.tar.gz";
    hash = "sha256-9mRyeupXnu5kSp9U72bRK0A/uc0JbF4K12jwBaD1Jpg=";
  };

  sourceRoot = "Sheprd-${finalAttrs.version}-x86_64-unknown-linux-gnu";

  nativeBuildInputs = [
    autoPatchelfHook
    makeWrapper
  ];
  buildInputs = [
    stdenv.cc.cc.lib
    alsa-lib
    libxcb
    libxkbcommon
  ];
  # The GPUI window dlopens these at run time.
  runtimeDependencies = [
    fontconfig
    freetype
    libglvnd
    libx11
    libxcursor
    libxi
    libxkbcommon
    libxrandr
    vulkan-loader
    wayland
  ];

  # The release bundles its own herdr-core (0.1.13) in bin/. It is left out: the profile
  # already carries packages/herdr-core, and two bin/herdr-core would collide in the
  # profile. The flake build did not bundle one either.
  installPhase = ''
    runHook preInstall
    mkdir -p $out
    cp -a bin share $out/
    rm $out/bin/herdr-core
    wrapProgram $out/bin/sheprd --prefix PATH : ${
      lib.makeBinPath [
        wl-clipboard
        xclip
      ]
    }
    runHook postInstall
  '';

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "Native client for Herdr, built with GPUI";
    homepage = "https://github.com/sheprd-labs/sheprd";
    platforms = [ "x86_64-linux" ];
    mainProgram = "sheprd";
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
})

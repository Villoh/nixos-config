{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  alsa-lib,
  libglvnd,
  libx11,
  libxcursor,
  libxi,
  libxkbcommon,
  libxrandr,
  pipewire,
  wayland,
  nix-update-script,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "zapfast";
  version = "0.21.1";

  src = fetchurl {
    url = "https://github.com/crmne/zapfast/releases/download/v${finalAttrs.version}/zapfast-v${finalAttrs.version}-x86_64-unknown-linux-gnu.tar.gz";
    hash = "sha256-x+5vg3BxWKSbiXCkwjbczI4dP52IrHP/g5uI8h5dAVA=";
  };

  sourceRoot = "zapfast-v${finalAttrs.version}-x86_64-unknown-linux-gnu";

  nativeBuildInputs = [ autoPatchelfHook ];
  buildInputs = [
    stdenv.cc.cc.lib
    alsa-lib
    pipewire
  ];
  # The GUI dlopens its Wayland, X11 and GL libraries at run time.
  runtimeDependencies = [
    libglvnd
    libx11
    libxcursor
    libxi
    libxkbcommon
    libxrandr
    wayland
  ];

  installPhase = ''
    runHook preInstall
    install -Dm755 zapfast $out/bin/zapfast
    install -Dm644 packaging/applications/zapfast.desktop $out/share/applications/zapfast.desktop
    install -Dm644 packaging/icons/zapfast.svg $out/share/icons/hicolor/scalable/apps/zapfast.svg
    install -Dm644 contrib/omarchy/zapfast.json.tpl $out/share/zapfast/omarchy/zapfast.json.tpl
    install -Dm755 contrib/omarchy/zapfast-theme $out/share/zapfast/omarchy/zapfast-theme
    runHook postInstall
  '';

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "Fast native WhatsApp client in Rust and egui";
    homepage = "https://github.com/crmne/zapfast";
    platforms = [ "x86_64-linux" ];
    mainProgram = "zapfast";
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
})

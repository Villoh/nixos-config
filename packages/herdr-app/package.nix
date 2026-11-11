{
  lib,
  stdenv,
  fetchurl,
  nix-update-script,
  autoPatchelfHook,
  makeWrapper,
  herdr-core,
  libxcb,
  libxkbcommon,
  wayland,
  vulkan-loader,
  libglvnd,
  libx11,
  libxcursor,
  libxi,
  libxrandr,
  fontconfig,
  freetype,
}:

# Upstream's prebuilt Linux release, so nothing is compiled here. Upstream's installer
# is not used: it pipes a script into sh and writes to ~/.local.
stdenv.mkDerivation (finalAttrs: {
  pname = "herdr-app";
  version = "0.1.15";

  src = fetchurl {
    url = "https://releases.herdr.dev/app/${finalAttrs.version}/herdr-app-linux-x86_64.tar.gz";
    hash = "sha256-+Z4eBL6CwOELL2nudAPKNDhvSA2SUR31hlr0cD52Vd0=";
  };

  sourceRoot = "herdr-app";

  nativeBuildInputs = [
    autoPatchelfHook
    makeWrapper
  ];
  buildInputs = [
    stdenv.cc.cc.lib
    libxcb
    libxkbcommon
  ];
  # Loaded with dlopen at run time, so they have to be on the RPATH.
  runtimeDependencies = [
    wayland
    libxkbcommon
    vulkan-loader
    libglvnd
    libx11
    libxcursor
    libxi
    libxrandr
    fontconfig
    freetype
  ];

  installPhase = ''
    runHook preInstall
    install -Dm755 herdr-app $out/bin/herdr-app
    install -Dm644 herdr-app.svg $out/share/icons/hicolor/scalable/apps/herdr-app.svg
    # The app looks for `hc` on PATH, and its terminals inherit it. Not linked into $out/bin,
    # so it cannot collide with the herdr-core bundled in the sheprd package.
    wrapProgram $out/bin/herdr-app --prefix PATH : ${herdr-core}/bin
    install -Dm644 /dev/stdin $out/share/applications/herdr-app.desktop <<EOF
    [Desktop Entry]
    Type=Application
    Name=Herdr
    Comment=Terminals and coding agents that keep running
    Exec=herdr-app
    Icon=herdr-app
    Terminal=false
    Categories=Development;
    StartupWMClass=herdr-app
    EOF
    runHook postInstall
  '';

  # The tarball lives on releases.herdr.dev; the versions are the tags of the GitHub repo.
  passthru.updateScript = nix-update-script {
    extraArgs = [
      "--url"
      "https://github.com/herdrdev/herdr-app"
    ];
  };

  meta = {
    description = "Desktop app for terminals and coding agents";
    homepage = "https://herdr.dev";
    license = lib.licenses.asl20;
    platforms = [ "x86_64-linux" ];
    mainProgram = "herdr-app";
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
})

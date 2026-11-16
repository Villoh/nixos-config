{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  dpkg,
  dbus,
  fontconfig,
  libglvnd,
  libx11,
  libxcb,
  libxcursor,
  libxi,
  libxkbcommon,
  wayland,
  nix-update-script,
}:

# Flectar Mail from upstream's .deb, run natively. Upstream ships no flake and nixpkgs has no
# package, so this stays until one of them exists. Not the Flatpak: alpha.7's has no clipboard
# on Wayland (flectar/mail#108, fixed by #122 on main, not released yet) because the sandbox
# hides the clipboard protocol from the app; a native binary is not sandboxed.
# The app looks for libpdfium in ../lib/flectar-mail relative to its binary, so keep that layout.
stdenv.mkDerivation (finalAttrs: {
  pname = "flectar-mail";
  version = "0.1.0-alpha.7";

  src = fetchurl {
    url = "https://github.com/flectar/mail/releases/download/v${finalAttrs.version}/flectar-mail_${
      builtins.replaceStrings [ "-" ] [ "." ] finalAttrs.version
    }_amd64.deb";
    hash = "sha256-KXL+bsDeQHWuAIJ41rzAGHFhVRuLdYg8saMMz0xV+C8=";
  };

  nativeBuildInputs = [
    autoPatchelfHook
    dpkg
  ];
  buildInputs = [
    stdenv.cc.cc.lib
    dbus
  ];
  # Loaded with dlopen at run time: the GPU and windowing stack.
  runtimeDependencies = [
    fontconfig
    libglvnd
    libx11
    libxcb
    libxcursor
    libxi
    libxkbcommon
    wayland
  ];

  unpackPhase = "dpkg-deb -x $src .";
  sourceRoot = ".";

  installPhase = ''
    runHook preInstall
    mkdir -p $out
    cp -a usr/bin usr/lib usr/share $out/
    # The .desktop file already points at `flectar-mail` on PATH, which is what the profile provides.
    runHook postInstall
  '';

  # Upstream only publishes alpha tags; the default "stable" filter would skip them.
  passthru.updateScript = nix-update-script {
    extraArgs = [ "--version=unstable" ];
  };

  meta = {
    description = "Native email client with IMAP, SMTP and JMAP support (prebuilt .deb)";
    homepage = "https://github.com/flectar/mail";
    license = lib.licenses.agpl3Only;
    platforms = [ "x86_64-linux" ];
    mainProgram = "flectar-mail";
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
})

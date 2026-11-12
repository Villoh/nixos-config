{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  makeWrapper,
  dpkg,
  alsa-lib,
  ffmpeg,
  fontconfig,
  freetype,
  libcdio,
  libcdio-paranoia,
  libx11,
  libxcb,
  libxkbcommon,
  openssl,
  vulkan-loader,
  wayland,
  nix-update-script,
}:

# The GPUI app from the nightly channel: the stable release is still the old Dioxus/WebKit
# app. This nightly is built from the same commit the `kopuz` flake input pins. It is a
# separate channel: the binaries are named *-nightly and use their own socket (kopuzd-nightly.sock).
stdenv.mkDerivation (finalAttrs: {
  pname = "kopuz";
  version = "0.68.0-nightly.20261112.2";

  src = fetchurl {
    url = "https://github.com/Kopuz-org/kopuz/releases/download/v${finalAttrs.version}/kopuz-nightly_${finalAttrs.version}_amd64.deb";
    hash = "sha256-bMZ/XPC6/2nSIc83slRZpmvN2fEb6PRb38A0dexr4Kg=";
  };

  nativeBuildInputs = [
    autoPatchelfHook
    dpkg
    makeWrapper
  ];
  buildInputs = [
    stdenv.cc.cc.lib
    alsa-lib
    libxcb
    libxkbcommon
    openssl
  ];

  unpackPhase = "dpkg-deb -x $src .";
  sourceRoot = ".";

  # The app looks for kopuzd-nightly beside itself, so all three stay together in bin/.
  # Same wrappers as the flake build: GPUI loads its window and GPU libraries at run time,
  # and kopuzd dlopens libcdio and runs ffmpeg.
  installPhase = ''
    runHook preInstall
    mkdir -p $out
    cp -a usr/bin usr/share $out/
    wrapProgram $out/bin/kopuz-nightly --prefix LD_LIBRARY_PATH : ${
      lib.makeLibraryPath [
        fontconfig
        freetype
        libx11
        libxcb
        libxkbcommon
        vulkan-loader
        wayland
      ]
    }
    wrapProgram $out/bin/kopuzd-nightly \
      --prefix PATH : ${lib.makeBinPath [ ffmpeg ]} \
      --prefix LD_LIBRARY_PATH : ${
        lib.makeLibraryPath [
          libcdio
          libcdio-paranoia
        ]
      }
    runHook postInstall
  '';

  # Published releases only: the repo also has a stray v2.0 tag, 1428 commits behind the
  # nightlies, that a tag search would pick as the newest version.
  passthru.updateScript = nix-update-script {
    extraArgs = [
      "--version=unstable"
      "--use-github-releases"
    ];
  };

  meta = {
    description = "Fast, modern music player with Jellyfin and local library support (nightly)";
    homepage = "https://github.com/Kopuz-org/kopuz";
    license = lib.licenses.eupl12;
    platforms = [ "x86_64-linux" ];
    mainProgram = "kopuz-nightly";
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
})

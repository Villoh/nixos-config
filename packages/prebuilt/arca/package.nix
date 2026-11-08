{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  makeDesktopItem,
  copyDesktopItems,
  libglvnd,
  libx11,
  libxcb,
  libxkbcommon,
  vulkan-loader,
  wayland,
  nix-update-script,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "arca";
  version = "0.9.0";

  src = fetchurl {
    url = "https://github.com/beyondhumane/arca/releases/download/v${finalAttrs.version}/arca-v${finalAttrs.version}-linux-x86_64.tar.gz";
    hash = "sha256-hvTsmuQxVDA9sX3COHIchDk2ILZNfP90jnt6t3BImDo=";
  };

  # The release tarball ships no icon; the same file the source build installs, at the tag.
  icon = fetchurl {
    url = "https://raw.githubusercontent.com/beyondhumane/arca/v${finalAttrs.version}/brand/arca-monolito-256.png";
    hash = "sha256-F1P8+OaTyy/PvmZ2I5/mvPuQ6NyvObbr/qKwCeL4d7A=";
  };

  sourceRoot = "arca-v${finalAttrs.version}-linux-x86_64";

  nativeBuildInputs = [
    autoPatchelfHook
    copyDesktopItems
  ];
  buildInputs = [ stdenv.cc.cc.lib ];
  # The GUI dlopens these at run time.
  runtimeDependencies = [
    libglvnd
    libx11
    libxcb
    libxkbcommon
    vulkan-loader
    wayland
  ];

  desktopItems = [
    (makeDesktopItem {
      name = "arca";
      desktopName = "Arca";
      genericName = "Archive Manager";
      comment = "Create, browse and extract ZIP and TAR archives";
      exec = "arca-gui %f";
      # Reverse-DNS so no icon theme can shadow it (Colloid ships an unrelated "arca").
      icon = "dev.beyondhumane.Arca";
      categories = [
        "Utility"
        "Archiving"
        "Compression"
      ];
      mimeTypes = [
        "application/zip"
        "application/x-tar"
        "application/x-compressed-tar"
      ];
      keywords = [
        "zip"
        "tar"
        "archive"
        "extract"
        "compress"
      ];
    })
  ];

  installPhase = ''
    runHook preInstall
    install -Dm755 arca $out/bin/arca
    install -Dm755 arca-gui $out/bin/arca-gui
    install -Dm644 $icon $out/share/icons/hicolor/256x256/apps/dev.beyondhumane.Arca.png
    install -Dm644 RAR-NOTICES.txt $out/share/licenses/arca/RAR-NOTICES.txt
    runHook postInstall
  '';

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "Fast and safe archive manager";
    homepage = "https://arca.beyondhumane.com";
    license = lib.licenses.asl20;
    platforms = [ "x86_64-linux" ];
    mainProgram = "arca";
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
})

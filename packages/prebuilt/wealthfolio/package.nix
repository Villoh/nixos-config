{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  dpkg,
  wrapGAppsHook3,
  cairo,
  dbus,
  gdk-pixbuf,
  glib,
  glib-networking,
  gtk3,
  libsoup_3,
  webkitgtk_4_1,
  nix-update-script,
}:

# Shadows nixpkgs' wealthfolio, like the source build in packages/wealthfolio.
stdenv.mkDerivation (finalAttrs: {
  pname = "wealthfolio";
  version = "3.12.0";

  src = fetchurl {
    url = "https://github.com/afadil/wealthfolio/releases/download/v${finalAttrs.version}/Wealthfolio_${finalAttrs.version}_amd64.deb";
    hash = "sha256-+TFYrMjtwqL1bHcMzaDdgO7lemLIUkGU9UQlWWQs64w=";
  };

  nativeBuildInputs = [
    autoPatchelfHook
    dpkg
    wrapGAppsHook3
  ];
  buildInputs = [
    stdenv.cc.cc.lib
    cairo
    dbus
    gdk-pixbuf
    glib
    glib-networking
    gtk3
    libsoup_3
    webkitgtk_4_1
  ];

  unpackPhase = "dpkg-deb -x $src .";
  sourceRoot = ".";

  installPhase = ''
    runHook preInstall
    mkdir -p $out
    cp -a usr/bin usr/share $out/
    runHook postInstall
  '';

  # Without this WebKitGTK 2.54 kills the window on Wayland (Gdk "Error 71 (Protocol error)"),
  # the same workaround Handy 0.10 applies itself.
  preFixup = ''
    gappsWrapperArgs+=(--set WEBKIT_DMABUF_RENDERER_FORCE_SHM 1)
  '';

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "Private, local-first personal finance tracker";
    homepage = "https://wealthfolio.app";
    platforms = [ "x86_64-linux" ];
    mainProgram = "Wealthfolio";
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
})

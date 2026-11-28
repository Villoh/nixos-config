{
  lib,
  stdenv,
  fetchurl,
  dpkg,
  autoPatchelfHook,
  wrapGAppsHook3,
  patchelf,
  alsa-lib,
  cairo,
  gdk-pixbuf,
  glib,
  gtk3,
  libayatana-appindicator,
  libevdev,
  libsoup_3,
  libx11,
  libxtst,
  xdotool,
  webkitgtk_4_1,
  wayland,
  xz,
  nix-update-script,
}:

# The upstream .deb (a Dioxus/wry app, so WebKitGTK + GTK 3). It finds its assets and soundpacks
# next to the binary (../lib/mechvibes, ../share/mechvibes), so the deb layout is kept as is.
# Typing is read from /dev/input: the user must be in the `input` group (see the host config),
# otherwise the window opens and nothing sounds.
stdenv.mkDerivation (finalAttrs: {
  pname = "mechvibes";
  version = "3.5.11";

  src = fetchurl {
    url = "https://github.com/hainguyents13/mechvibes/releases/download/v${finalAttrs.version}/mechvibes_${finalAttrs.version}_amd64.deb";
    hash = "sha256-S/L0C4MKHAqBWM77++DG4+YyC9xkPAxEe+elJZSyWJw=";
  };

  nativeBuildInputs = [
    dpkg
    patchelf
    autoPatchelfHook
    wrapGAppsHook3
  ];
  buildInputs = [
    stdenv.cc.cc.lib
    alsa-lib
    cairo
    gdk-pixbuf
    glib
    gtk3
    libevdev
    libsoup_3
    libx11
    libxtst
    xdotool
    webkitgtk_4_1
    wayland
    xz
  ];
  # The tray icon library is dlopen'd at run time.
  runtimeDependencies = [ libayatana-appindicator ];

  unpackPhase = "dpkg-deb -x $src .";

  # The deb layout is kept under $out/usr: with /usr/ in its own path the app keeps settings in
  # ~/.local/share/mechvibes; anywhere else it writes next to the binary, a read-only store path.
  dontWrapGApps = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    cp -a usr $out/usr
    # shortcut: the deb links libxdo.so.3, nixpkgs ships .so.4. Only xdo_new, xdo_free and
    # xdo_send_keysequence_window are used and they did not change; drop this if upstream
    # relinks, or if keystroke injection (on-screen keyboard option) misbehaves.
    patchelf --replace-needed libxdo.so.3 libxdo.so.4 $out/usr/bin/mechvibes
    substituteInPlace $out/usr/share/applications/mechvibes.desktop \
      --replace-fail "Exec=mechvibes" "Exec=$out/bin/mechvibes"
    ln -s $out/usr/share $out/share
    runHook postInstall
  '';

  postFixup = ''
    wrapGApp $out/usr/bin/mechvibes
    ln -s $out/usr/bin/mechvibes $out/bin/mechvibes
  '';

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "Mechanical keyboard and mouse sound simulator";
    homepage = "https://mechvibes.com";
    license = lib.licenses.mit;
    platforms = [ "x86_64-linux" ];
    mainProgram = "mechvibes";
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
})

# Brave Origin, from Brave's own .deb. nixpkgs dropped brave and brave-origin on
# 2026-11-03 (no committer among the maintainers); this is its make-brave.nix, reduced
# to the Origin flavor on x86_64-linux.
#
# Brave tags Release, Beta and Nightly builds alike on GitHub and does not mark them
# consistently as prereleases, so the version comes from versions.brave.com, the
# channel Brave's own updater reads: passthru.nixup.versionUrl tells nixup where.
{
  lib,
  stdenv,
  fetchurl,
  buildPackages,
  writeShellScript,
  curl,
  nix-update,
  alsa-lib,
  at-spi2-atk,
  at-spi2-core,
  atk,
  cairo,
  cups,
  dbus,
  dpkg,
  expat,
  fontconfig,
  freetype,
  gdk-pixbuf,
  glib,
  adwaita-icon-theme,
  gsettings-desktop-schemas,
  gtk3,
  gtk4,
  qt6,
  libx11,
  libxscrnsaver,
  libxcomposite,
  libxcursor,
  libxdamage,
  libxext,
  libxfixes,
  libxi,
  libxrandr,
  libxrender,
  libxtst,
  libdrm,
  libkrb5,
  libuuid,
  libxkbcommon,
  libxshmfence,
  libgbm,
  nspr,
  nss,
  pango,
  pipewire,
  snappy,
  udev,
  wayland,
  xdg-utils,
  coreutils,
  libxcb,
  zlib,
  libpulseaudio,
  libGL,
  libva,
  # Always-on command line arguments, e.g. "--disable-gpu".
  commandLineArgs ? "",
}:

let
  pname = "brave-origin";
  version = "1.99.56";
  dir = "opt/brave.com/brave-origin";

  deps = [
    alsa-lib
    at-spi2-atk
    at-spi2-core
    atk
    cairo
    cups
    dbus
    expat
    fontconfig
    freetype
    gdk-pixbuf
    glib
    gtk3
    gtk4
    libdrm
    libx11
    libGL
    libxkbcommon
    libxscrnsaver
    libxcomposite
    libxcursor
    libxdamage
    libxext
    libxfixes
    libxi
    libxrandr
    libxrender
    libxshmfence
    libxtst
    libuuid
    libgbm
    nspr
    nss
    pango
    pipewire
    udev
    wayland
    libxcb
    zlib
    snappy
    libkrb5
    qt6.qtbase
    libpulseaudio # USB audio devices
    libva # VA-API video acceleration
  ];

  rpath = lib.makeLibraryPath deps + ":" + lib.makeSearchPathOutput "lib" "lib64" deps;

  enableFeatures = [
    "AcceleratedVideoDecodeLinuxGL"
    "AcceleratedVideoEncoder"
  ];
  disableFeatures = [
    "OutdatedBuildDetector" # updates come from Nix
    # VA-API: https://github.com/brave/brave-browser/issues/20935
    "UseChromeOSDirectVideoDecoder"
  ];
in
stdenv.mkDerivation {
  inherit pname version;

  __structuredAttrs = true;
  strictDeps = true;

  src = fetchurl {
    url = "https://github.com/brave/brave-browser/releases/download/v${version}/brave-origin_${version}_amd64.deb";
    hash = "sha256-tamLNby63nb9MrOzIkHdKGzGXvRSrlnczx8NrAJne68=";
  };

  dontConfigure = true;
  dontBuild = true;
  dontPatchELF = true;
  doInstallCheck = true;

  nativeBuildInputs = [
    dpkg
    # override doesn't preserve splicing: https://github.com/NixOS/nixpkgs/issues/132651
    (buildPackages.wrapGAppsHook3.override { makeWrapper = buildPackages.makeShellWrapper; })
  ];

  buildInputs = [
    # GSETTINGS_SCHEMAS_PATH
    glib
    gsettings-desktop-schemas
    gtk3
    gtk4
    # XDG_ICON_DIRS
    adwaita-icon-theme
  ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    cp -R usr/share $out
    cp -R opt $out/opt

    wrapper=$out/${dir}/brave-origin
    substituteInPlace $wrapper \
      --replace-fail /bin/bash ${stdenv.shell} \
      --replace-fail 'CHROME_WRAPPER' 'WRAPPER'
    ln -sf $wrapper $out/bin/brave-origin

    for exe in $out/${dir}/{brave,chrome_crashpad_handler}; do
      patchelf \
        --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" \
        --set-rpath "${rpath}" $exe
    done

    # Icon themes (Colloid, Papirus...) ship `brave` but not `brave-origin`, so a
    # launcher trims the name and shows the regular Brave logo: use an absolute path.
    substituteInPlace $out/share/applications/{brave-origin,com.brave.Origin}.desktop \
      --replace-fail /usr/bin/brave-origin-stable $out/bin/brave-origin \
      --replace-fail "Icon=brave-origin" "Icon=$out/share/icons/hicolor/256x256/apps/brave-origin.png"
    substituteInPlace $out/share/gnome-control-center/default-apps/brave-origin.xml \
      --replace-fail /opt/brave.com $out/opt/brave.com
    substituteInPlace $out/${dir}/default-app-block \
      --replace-fail /opt/brave.com $out/opt/brave.com

    for size in 16 24 32 48 64 128 256; do
      mkdir -p $out/share/icons/hicolor/''${size}x''${size}/apps
      ln -s $out/${dir}/product_logo_$size.png \
        $out/share/icons/hicolor/''${size}x''${size}/apps/brave-origin.png
    done

    ln -sf ${xdg-utils}/bin/xdg-settings $out/${dir}/xdg-settings
    ln -sf ${xdg-utils}/bin/xdg-mime $out/${dir}/xdg-mime

    runHook postInstall
  '';

  preFixup = ''
    gappsWrapperArgs+=(
      --prefix LD_LIBRARY_PATH : ${rpath}
      --prefix PATH : ${lib.makeBinPath deps}
      --suffix PATH : ${
        lib.makeBinPath [
          xdg-utils
          coreutils
        ]
      }
      --set CHROME_WRAPPER brave-origin
      --add-flags "--enable-features=${lib.concatStringsSep "," enableFeatures}\''${NIXOS_OZONE_WL:+\''${WAYLAND_DISPLAY:+,WaylandWindowDecorations --enable-wayland-ime=true}}"
      --add-flags "--disable-features=${lib.concatStringsSep "," disableFeatures}"
      --add-flags "\''${NIXOS_OZONE_WL:+\''${WAYLAND_DISPLAY:+--ozone-platform-hint=auto}}"
      --add-flags ${lib.escapeShellArg commandLineArgs}
    )
  '';

  installCheckPhase = ''
    # The upstream wrapper hides errors.
    $out/${dir}/brave --version
  '';

  passthru = rec {
    # nixup reads the same channel (nix-update alone would follow GitHub's tags).
    nixup.versionUrl = "https://versions.brave.com/latest/origin-release-linux-x64.version";
    updateScript = writeShellScript "update-brave-origin" ''
      set -eu
      version=$(${lib.getExe curl} -fsS ${nixup.versionUrl})
      exec ${lib.getExe nix-update} --flake brave-origin --version="$version" "$@"
    '';
  };

  meta = {
    homepage = "https://brave.com/origin/";
    description = "Brave browser without rewards, wallet or AI (Origin variant)";
    changelog =
      "https://github.com/brave/brave-browser/blob/master/CHANGELOG_DESKTOP_ORIGIN.md#"
      + lib.replaceStrings [ "." ] [ "" ] version;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    license = lib.licenses.mpl20;
    platforms = [ "x86_64-linux" ];
    mainProgram = "brave-origin";
  };
}

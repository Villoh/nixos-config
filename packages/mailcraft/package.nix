{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  dpkg,
  fontconfig,
  libglvnd,
  libx11,
  libxcb,
  libxcursor,
  libxi,
  libxkbcommon,
  libxrandr,
  vulkan-loader,
  wayland,
  nix-update-script,
}:

# MailCraft (UCSLabs) from upstream's .deb, run natively. Upstream ships no flake and nixpkgs has
# no package. Native binary, not the Flatpak, like flectar-mail (no sandbox, so Wayland clipboard
# and the keyring work as is).
stdenv.mkDerivation (finalAttrs: {
  pname = "mailcraft";
  version = "0.15.0";

  src = fetchurl {
    url = "https://github.com/UCSLabs/mailcraft/releases/download/v${finalAttrs.version}/mailcraft-${finalAttrs.version}-linux-x86_64.deb";
    hash = "sha256-GM1tP+mtaQbmm6yRVHxlFQSeYm0zH24M+amnJmqx7nk=";
  };

  nativeBuildInputs = [
    autoPatchelfHook
    dpkg
  ];
  buildInputs = [ stdenv.cc.cc.lib ];
  # Loaded with dlopen at run time: the GPU and windowing stack.
  runtimeDependencies = [
    fontconfig
    libglvnd
    libx11
    libxcb
    libxcursor
    libxi
    libxkbcommon
    libxrandr
    vulkan-loader
    wayland
  ];

  unpackPhase = "dpkg-deb -x $src .";
  sourceRoot = ".";

  installPhase = ''
    runHook preInstall
    mkdir -p $out
    cp -a usr/bin usr/share $out/
    runHook postInstall
  '';

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "Open-source mail, calendar, contacts and tasks program in Rust (prebuilt .deb)";
    homepage = "https://mailcraft.work";
    license = with lib.licenses; [
      mit
      asl20
    ];
    platforms = [ "x86_64-linux" ];
    mainProgram = "mailcraft";
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
})

{
  stdenv,
  stdenvNoCC,
  fetchurl,
  autoPatchelfHook,
  nix-update-script,
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "padpoll";
  version = "1.1.0";

  src = fetchurl {
    url = "https://github.com/PabloStarOk/padpoll/releases/download/v${finalAttrs.version}/padpoll-linux.tar.gz";
    hash = "sha256-0ev13g5Q8L+n8j/v87fx/O4Kkd1RQmzI5YJ5QbI+xXE=";
  };

  nativeBuildInputs = [ autoPatchelfHook ];
  buildInputs = [ stdenv.cc.cc.lib ];
  dontUnpack = true;

  installPhase = ''
    install -d "$out/bin"
    tar -xzf "$src" -C "$out/bin" padpoll
    chmod 755 "$out/bin/padpoll"
  '';

  passthru.updateScript = nix-update-script { };

  meta = {
    homepage = "https://github.com/PabloStarOk/padpoll";
    mainProgram = "padpoll";
    platforms = [ "x86_64-linux" ];
  };
})

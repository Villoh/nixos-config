{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
}:

# Runs Herdr App's terminals and agents. Upstream publishes no GitHub releases for it, so
# bump version and hash by hand from https://releases.herdr.dev/core/latest.json.
stdenv.mkDerivation (finalAttrs: {
  pname = "herdr-core";
  version = "0.1.18";

  src = fetchurl {
    url = "https://releases.herdr.dev/core/${finalAttrs.version}/herdr-core-linux-x86_64.tar.gz";
    hash = "sha256-Wy+Xy0sqnXprLMWUJiggPtn7t8wMK0sJrYpvVkjiRrc=";
  };

  sourceRoot = ".";

  nativeBuildInputs = [ autoPatchelfHook ];
  buildInputs = [ stdenv.cc.cc.lib ];

  installPhase = ''
    runHook preInstall
    install -Dm755 herdr-core $out/bin/herdr-core
    ln -s herdr-core $out/bin/hc
    runHook postInstall
  '';

  meta = {
    description = "Session core that keeps Herdr's terminals and agents alive";
    homepage = "https://herdr.dev";
    license = lib.licenses.asl20;
    platforms = [ "x86_64-linux" ];
    mainProgram = "hc";
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
})

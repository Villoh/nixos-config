{
  lib,
  stdenv,
  fetchurl,
  nix-update-script,
  autoPatchelfHook,
}:

# Runs Herdr App's terminals and agents.
stdenv.mkDerivation (finalAttrs: {
  pname = "herdr-core";
  version = "0.1.20";

  src = fetchurl {
    url = "https://releases.herdr.dev/core/${finalAttrs.version}/herdr-core-linux-x86_64.tar.gz";
    hash = "sha256-rGuGiQxFGjdYRiCqpDi3G8DQvUMKLnwdfglfBSxBTnQ=";
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

  # The tarball lives on releases.herdr.dev; the versions are the tags of the GitHub repo.
  passthru.updateScript = nix-update-script {
    extraArgs = [
      "--url"
      "https://github.com/herdrdev/herdr-core"
    ];
  };

  meta = {
    description = "Session core that keeps Herdr's terminals and agents alive";
    homepage = "https://herdr.dev";
    license = lib.licenses.asl20;
    platforms = [ "x86_64-linux" ];
    mainProgram = "hc";
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
})

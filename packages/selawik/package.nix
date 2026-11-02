{
  lib,
  stdenvNoCC,
  fetchzip,
  nix-update-script,
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "selawik";
  version = "1.01";

  src = fetchzip {
    url = "https://github.com/microsoft/Selawik/releases/download/${finalAttrs.version}/Selawik_Release.zip";
    hash = "sha256-BbjXJ8HFXrRklMOnGXyZIZeQ5Oksda4AqQXHmNqN6AQ=";
    stripRoot = false;
  };

  installPhase = ''
    install -Dm644 *.ttf -t $out/share/fonts/truetype
  '';

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "Open-source replacement for Segoe UI";
    homepage = "https://github.com/microsoft/Selawik";
    license = lib.licenses.ofl;
    platforms = lib.platforms.all;
  };
})

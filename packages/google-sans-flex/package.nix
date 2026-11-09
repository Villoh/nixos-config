{
  lib,
  stdenvNoCC,
  fetchzip,
  nix-update-script,
}:

# Not in nixpkgs: google-fonts there predates the family. One variable TTF, the same
# family name ("Google Sans Flex") that Dux Shell 2.0 asks for.
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "google-sans-flex";
  version = "5.000";

  src = fetchzip {
    url = "https://github.com/googlefonts/googlesans-flex/releases/download/v${finalAttrs.version}/GoogleSansFlex-v${finalAttrs.version}.zip";
    hash = "sha256-NkCK4oZtmkuVuMFnZiVMeJyG0zuy9Ew0sxUQXzA4oKY=";
    stripRoot = false;
  };

  installPhase = ''
    runHook preInstall
    install -Dm644 *.ttf -t $out/share/fonts/truetype
    runHook postInstall
  '';

  passthru.updateScript = nix-update-script { extraArgs = [ "--use-github-releases" ]; };

  meta = {
    description = "Google Sans Flex, Google's variable sans-serif typeface";
    homepage = "https://github.com/googlefonts/googlesans-flex";
    license = lib.licenses.ofl;
    platforms = lib.platforms.all;
  };
})

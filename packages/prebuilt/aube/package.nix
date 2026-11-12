{
  lib,
  stdenvNoCC,
  fetchurl,
  versionCheckHook,
  nix-update-script,
}:

# Upstream's static musl release: nothing to patch. nixpkgs' aube is behind (1.32 when
# this was written) and its source build is not in cache.nixos.org; the source package
# waiting for a binary cache is ../../aube.
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "aube";
  version = "2.10.0";

  src = fetchurl {
    url = "https://github.com/aubepkg/aube/releases/download/v${finalAttrs.version}/aube-v${finalAttrs.version}-x86_64-unknown-linux-musl.tar.gz";
    hash = "sha256-UciMSPeEqoLKb54s7XOqnFHlSCpb4OFnC4jMWXaf4us=";
  };

  # The tarball holds the bare binaries, no top-level folder.
  sourceRoot = ".";

  installPhase = ''
    runHook preInstall
    install -Dm755 -t $out/bin aube aubr aubx
    runHook postInstall
  '';

  nativeInstallCheckInputs = [ versionCheckHook ];
  doInstallCheck = true;

  # Same rule as nixpkgs' aube: published releases, not every tag.
  passthru.updateScript = nix-update-script { extraArgs = [ "--use-github-releases" ]; };

  meta = {
    description = "Fast Node.js package manager";
    homepage = "https://github.com/aubepkg/aube";
    changelog = "https://github.com/aubepkg/aube/blob/v${finalAttrs.version}/CHANGELOG.md";
    license = lib.licenses.mit;
    platforms = [ "x86_64-linux" ];
    mainProgram = "aube";
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
})

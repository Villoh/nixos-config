{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  nix-update-script,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "workmux";
  version = "0.1.282";

  src = fetchurl {
    url = "https://github.com/raine/workmux/releases/download/v${finalAttrs.version}/workmux-linux-amd64.tar.gz";
    hash = "sha256-+OME9Feh4LR8bDMXET1usfzUTfRvIzzINuJhUnm7lO4=";
  };

  # The tarball holds the bare binary, no top-level folder.
  sourceRoot = ".";

  nativeBuildInputs = [ autoPatchelfHook ];
  buildInputs = [ stdenv.cc.cc.lib ];

  installPhase = ''
    runHook preInstall
    install -Dm755 workmux $out/bin/workmux
    runHook postInstall
  '';

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "Git worktrees plus agent status in tmux";
    homepage = "https://github.com/raine/workmux";
    platforms = [ "x86_64-linux" ];
    mainProgram = "workmux";
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
})

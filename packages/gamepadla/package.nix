{
  fetchFromGitHub,
  lib,
  makeWrapper,
  nix-update-script,
  python3,
  stdenvNoCC,
}:

# The original Gamepadla tester (cakama3a/Polling). Single script: it uploads every result to
# gamepadla.com and writes data.txt to the current directory. See plus.nix for the CLI/GUI fork.
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "gamepadla";
  # Python.py is identical at this tag and at master; version.txt upstream is stale (1.2.0.1).
  version = "1.3.1.4";

  src = fetchFromGitHub {
    owner = "cakama3a";
    repo = "Polling";
    tag = finalAttrs.version;
    hash = "sha256-N5GeSijB1bIai8Srm6aGf9yBGL6RynyyoBvMepGw+YA=";
  };

  nativeBuildInputs = [ makeWrapper ];

  dontBuild = true;
  installPhase = ''
    runHook preInstall
    install -Dm644 Python.py $out/share/gamepadla/Python.py
    makeWrapper ${
      python3.withPackages (p: with p; [ pygame numpy requests colorama ])
    }/bin/python $out/bin/gamepadla --add-flags $out/share/gamepadla/Python.py
    runHook postInstall
  '';

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "Gamepad polling rate tester (original Gamepadla / Polling)";
    homepage = "https://github.com/cakama3a/Polling";
    license = lib.licenses.mit;
    mainProgram = "gamepadla";
  };
})

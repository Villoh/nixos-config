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
stdenvNoCC.mkDerivation {
  pname = "gamepadla";
  version = "1.2.0.1-unstable-2026-01-18";

  src = fetchFromGitHub {
    owner = "cakama3a";
    repo = "Polling";
    rev = "8c34ed6fc14c3bce49c80e03f4618749aa1424f8";
    hash = "sha256-SRTCnb82jvXtMGRX2I0S2zPyVWa3/orjUFfBmQGUfGc=";
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

  passthru.updateScript = nix-update-script { extraArgs = [ "--version=branch" ]; };

  meta = {
    description = "Gamepad polling rate tester (original Gamepadla / Polling)";
    homepage = "https://github.com/cakama3a/Polling";
    license = lib.licenses.mit;
    mainProgram = "gamepadla";
  };
}

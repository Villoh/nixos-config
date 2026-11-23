{
  fetchFromGitHub,
  fetchPypi,
  lib,
  nix-update-script,
  python3Packages,
  qt6,
}:

let
  # Not in nixpkgs. Only gamepadla-plus uses it, so it stays private to this file.
  freesimpleguiqt = python3Packages.buildPythonPackage rec {
    pname = "freesimpleguiqt";
    version = "2.0.0";
    pyproject = true;
    src = fetchPypi {
      inherit pname version;
      hash = "sha256-xY8nmGQsR0qemmhnmVs6pImH3L4YcS6K9OcovYOGT/o=";
    };
    build-system = [ python3Packages.setuptools ];
    dependencies = [ python3Packages.pyside6 ];
    # Importing it loads Qt, which needs a display; nothing else to test.
    doCheck = false;
  };
in
python3Packages.buildPythonApplication rec {
  pname = "gamepadla-plus";
  version = "1.9.1";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "WyvernIXTL";
    repo = "gamepadla-plus";
    tag = "v${version}";
    hash = "sha256-2htuCWZpE9ooZa7NMzM4fW7gxLln/0ZcwrqikWvYOPc=";
  };

  build-system = [ python3Packages.hatchling ];

  # Upstream pins tight ranges from uv.lock (typer, rich, numpy...); nixpkgs runs slightly behind.
  pythonRelaxDeps = true;

  dependencies = with python3Packages; [
    colorama
    darkdetect
    freesimpleguiqt
    numpy
    pygame-ce
    pyside6
    requests
    rich
    tqdm
    typer
  ];

  nativeBuildInputs = [ qt6.wrapQtAppsHook ];
  buildInputs = [
    qt6.qtbase
    qt6.qtwayland
  ];
  dontWrapQtApps = true;
  preFixup = ''
    makeWrapperArgs+=("''${qtWrapperArgs[@]}")
  '';

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "Gamepad polling rate and latency tester (CLI and GUI)";
    homepage = "https://github.com/WyvernIXTL/gamepadla-plus";
    license = lib.licenses.mit;
    mainProgram = "gamepadla-plus";
  };
}

{
  copyDesktopItems,
  fetchFromGitHub,
  fetchPypi,
  lib,
  makeDesktopItem,
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

  # Upstream follows the system theme, and its light variant (TanBlue) is a glaring beige.
  postPatch = ''
    substituteInPlace gamepadla_plus/gui.py \
      --replace-fail 'dark_mode_is_enabled = check_dark_mode_enabled()' 'dark_mode_is_enabled = True'
  '';

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

  nativeBuildInputs = [
    copyDesktopItems
    qt6.wrapQtAppsHook
  ];
  buildInputs = [
    qt6.qtbase
    qt6.qtwayland
  ];
  dontWrapQtApps = true;
  preFixup = ''
    makeWrapperArgs+=("''${qtWrapperArgs[@]}")
  '';

  # Upstream ships no .desktop file. Absolute Exec (@out@ filled in below) so a mise shim of the same name cannot win.
  desktopItems = [
    (makeDesktopItem {
      name = "gamepadla-plus";
      desktopName = "Gamepadla+";
      comment = "Gamepad polling rate and latency tester";
      exec = "@out@/bin/gamepadla-plus";
      icon = "gamepadla-plus";
      categories = [ "Utility" ];
    })
  ];
  postInstall = ''
    install -Dm644 icon/gamepadla-plus-icon.svg \
      $out/share/icons/hicolor/scalable/apps/gamepadla-plus.svg
  '';

  postFixup = ''
    substituteInPlace $out/share/applications/gamepadla-plus.desktop --replace-fail @out@ $out
  '';

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "Gamepad polling rate and latency tester (CLI and GUI)";
    homepage = "https://github.com/WyvernIXTL/gamepadla-plus";
    license = lib.licenses.mit;
    mainProgram = "gamepadla-plus";
  };
}

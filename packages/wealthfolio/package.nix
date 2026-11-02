{
  lib,
  stdenv,
  fetchFromGitHub,
  cargo-tauri,
  jq,
  libsoup_3,
  moreutils,
  nodejs,
  openssl,
  perl,
  pkg-config,
  pnpm_10,
  fetchPnpmDeps,
  pnpmConfigHook,
  rustPlatform,
  webkitgtk_4_1,
  wrapGAppsHook3,
  nix-update-script,
}:
# Copied from nixpkgs (pkgs/by-name/we/wealthfolio): nixpkgs runs behind upstream.
# Drop this directory and the `wealthfolio` entry in ../default.nix once nixpkgs catches up.
stdenv.mkDerivation (finalAttrs: {
  pname = "wealthfolio";
  version = "3.11.0";

  src = fetchFromGitHub {
    owner = "wealthfolio";
    repo = "wealthfolio";
    rev = "v${finalAttrs.version}";
    hash = "sha256-1caBvxUE4JRcRyHwyxfxVITF7QMWjWnnoIkkBXfUh0g=";
  };

  pnpmDeps = fetchPnpmDeps {
    inherit (finalAttrs) src pname version;
    pnpm = pnpm_10;
    fetcherVersion = 4;
    hash = "sha256-InrKZIkoQPNpH+X5oolAUwAs9HtkG6F9ew7sfaYykpY=";
  };

  cargoRoot = ".";
  buildAndTestSubdir = finalAttrs.cargoRoot;

  cargoDeps = rustPlatform.fetchCargoVendor {
    inherit (finalAttrs)
      pname
      version
      src
      cargoRoot
      ;
    hash = "sha256-zim5nmTBsxvZqU7iobPf5orM0MAJLoXq5rvNgeM8+LE=";
  };

  nativeBuildInputs = [
    cargo-tauri.hook
    jq
    moreutils
    nodejs
    perl # 3.11 builds vendored OpenSSL (SQLCipher)
    pkg-config
    pnpmConfigHook
    pnpm_10
    rustPlatform.cargoSetupHook
    wrapGAppsHook3
  ];

  buildInputs = [
    libsoup_3
    openssl
    webkitgtk_4_1
  ];

  postPatch = ''
    jq \
      '.plugins.updater.endpoints = [ ]
      | .bundle.createUpdaterArtifacts = false' \
      apps/tauri/tauri.conf.json \
      | sponge apps/tauri/tauri.conf.json
  '';

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "Beautiful Private and Secure Desktop Investment Tracking Application";
    homepage = "https://wealthfolio.app/";
    license = lib.licenses.agpl3Only;
    mainProgram = "Wealthfolio";
    maintainers = with lib.maintainers; [ kilianar ];
    platforms = lib.platforms.linux;
  };
})

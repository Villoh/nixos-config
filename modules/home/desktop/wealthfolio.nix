{
  fetchFromGitHub,
  fetchPnpmDeps,
  perl,
  pnpm_10,
  rustPlatform,
  wealthfolio,
}:

# nixpkgs ya incluye `pkgs.wealthfolio` (en la 3.8.0 al escribir esto), pero va
# por detrás de upstream. Este override lo sube a la 3.11.0; cuando nixpkgs lo
# alcance, borrar este archivo y usar `pkgs.wealthfolio` directamente.
wealthfolio.overrideAttrs (
  finalAttrs: old: {
    version = "3.11.0";

    src = fetchFromGitHub {
      owner = "wealthfolio";
      repo = "wealthfolio";
      rev = "v${finalAttrs.version}";
      hash = "sha256-1caBvxUE4JRcRyHwyxfxVITF7QMWjWnnoIkkBXfUh0g=";
    };

    # 3.11 compila OpenSSL vendorizado (SQLCipher), que necesita perl.
    nativeBuildInputs = old.nativeBuildInputs ++ [ perl ];

    pnpmDeps = fetchPnpmDeps {
      inherit (finalAttrs) src pname version;
      pnpm = pnpm_10;
      fetcherVersion = 4;
      hash = "sha256-InrKZIkoQPNpH+X5oolAUwAs9HtkG6F9ew7sfaYykpY=";
    };

    cargoDeps = rustPlatform.fetchCargoVendor {
      inherit (finalAttrs)
        pname
        version
        src
        cargoRoot
        ;
      hash = "sha256-zim5nmTBsxvZqU7iobPf5orM0MAJLoXq5rvNgeM8+LE=";
    };
  }
)

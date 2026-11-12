# Packages that are not in nixpkgs (or run ahead of it). Every one carries
# `passthru.updateScript`, so `nix-update --flake <name>` bumps version and hashes,
# except herdr-agent-icons (a single font file pinned to a commit).
# Exposed as `packages.<system>.*` and, through `overlays.default`, as `pkgs.<name>`.
pkgs:
let
  # TEMPORARY prebuilt releases, see prebuilt/default.nix.
  prebuilt = import ./prebuilt pkgs;
in
rec {
  flectar-mail = pkgs.callPackage ./flectar-mail/package.nix { };
  tunnel-agent = pkgs.callPackage ./tunnel-agent/package.nix { };
  google-sans-flex = pkgs.callPackage ./google-sans-flex/package.nix { };
  # Herdr App under evaluation: a prebuilt release, so nothing is compiled.
  herdr-core = pkgs.callPackage ./herdr-core/package.nix { };
  herdr-app = pkgs.callPackage ./herdr-app/package.nix { inherit herdr-core; };
  herdr-agent-icons = pkgs.callPackage ./herdr-agent-icons/package.nix { };
  # Shadows nixpkgs' wealthfolio on purpose: nixpkgs runs behind upstream.
  # PENDING: cache. Source build, swapped for the prebuilt release meanwhile.
  # wealthfolio = pkgs.callPackage ./wealthfolio/package.nix { };
  wealthfolio = prebuilt.wealthfolio-bin;
  # Music player under evaluation: prebuilt release, upstream ships no flake.
  meiro = pkgs.callPackage ./meiro/package.nix { };
  # nixpkgs removed it (2026-11-03); Brave's own .deb.
  brave-origin = pkgs.callPackage ./brave-origin/package.nix { };
}
// prebuilt

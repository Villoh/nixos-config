# Packages that are not in nixpkgs (or run ahead of it). Every one carries
# `passthru.updateScript`, so `nix-update --flake <name>` bumps version and hashes,
# except herdr-agent-icons (a single font file pinned to a commit), and hyprgrass and
# hyprglass (tags that track the Hyprland version).
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
  # Shadows nixpkgs' aube on purpose: nixpkgs runs behind upstream.
  # PENDING: cache. Source build, swapped for the prebuilt release (aube-bin) meanwhile.
  # aube = pkgs.callPackage ./aube/package.nix { };
  # Music player under evaluation: prebuilt release, upstream ships no flake.
  meiro = pkgs.callPackage ./meiro/package.nix { };
  # Gamepad polling/latency testers: not in nixpkgs. The fork needs freesimpleguiqt for its GUI.
  gamepadla = pkgs.callPackage ./gamepadla/package.nix { };
  gamepadla-plus = pkgs.callPackage ./gamepadla/plus.nix { };
  # Touchscreen gestures plugin, built against the Hyprland of this nixpkgs.
  hyprgrass = pkgs.callPackage ./hyprgrass/package.nix { };
  # Liquid Glass plugin, built against the Hyprland of this nixpkgs.
  hyprglass = pkgs.callPackage ./hyprglass/package.nix { };
}
// prebuilt

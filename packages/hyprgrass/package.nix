{
  callPackage,
  fetchFromGitHub,
}:

# Touchscreen gestures for Hyprland. nixpkgs' hyprgrass tracks Hyprland 0.55 and its wf-touch
# is newer than the API hyprgrass expects, so this uses upstream's own Nix files at the tag
# that matches Hyprland. Bump `rev` and `tag` together with Hyprland (tags are
# hl-<hyprland version>), then set the hash from `nix flake prefetch github:horriblename/hyprgrass/<rev>`.
let
  rev = "hl-0.57.2";
  src = fetchFromGitHub {
    owner = "horriblename";
    repo = "hyprgrass";
    inherit rev;
    hash = "sha256-RcoDB1XNsGengdoZ3KCsbVGzex6oE7t9ZKkSao/1ctU=";
  };
in
(callPackage "${src}/nix/default.nix" {
  wf-touch = callPackage "${src}/nix/wf-touch.nix" { };
  tag = "0.57.2";
  commit = rev;
}).overrideAttrs
  (old: {
    # Tells nixup the pin is on purpose, so check does not ask for an update script.
    passthru = (old.passthru or { }) // {
      nixup.pinned = "tag that matches the Hyprland version; bump it with Hyprland";
    };
  })

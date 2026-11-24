{
  lib,
  fetchFromGitHub,
  hyprlandPlugins,
  wayland-scanner,
}:

# Liquid Glass for Hyprland. Each release targets one Hyprland minor (branch hyprland-X.Y):
# bump `version` together with Hyprland, then set the hash from
# `nix flake prefetch github:hyprnux/hyprglass/v<version>`. A mismatch does not crash, the
# plugin pauses (`hyprctl plugin list` says why).
hyprlandPlugins.mkHyprlandPlugin (finalAttrs: {
  pluginName = "hyprglass";
  version = "1.2.0"; # hyprland-0.57

  src = fetchFromGitHub {
    owner = "hyprnux";
    repo = "hyprglass";
    tag = "v${finalAttrs.version}";
    hash = "sha256-yWfeuLNVhoLYDmrFrZ8YDoHSFObwvKoplwHvTulPWTs=";
  };

  nativeBuildInputs = [ wayland-scanner ];

  makeFlags = [ "HYPRGLASS_VERSION=${finalAttrs.version}" ];

  # Home Manager loads lib/lib<pname>.so.
  installPhase = ''
    runHook preInstall
    install -Dm755 hyprglass.so $out/lib/libhyprglass.so
    runHook postInstall
  '';

  passthru.nixup.pinned = "release that matches the Hyprland version; bump it with Hyprland";

  meta = {
    description = "Liquid Glass inspired plugin for Hyprland";
    homepage = "https://github.com/hyprnux/hyprglass";
    license = lib.licenses.bsd3;
    platforms = lib.platforms.linux;
  };
})

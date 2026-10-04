{
  inputs,
  lib,
  pkgs,
  ...
}:

let
  plugins = inputs.dms-plugin-registry.packages.${pkgs.stdenv.hostPlatform.system};
  enabledPlugins = [
    "bitwarden"
    "dankKDEConnect"
    "quickCapture"
    "wallpaperCarousel"
    "dockerManager"
    "dankscale"
    "aiOverviewControl"
    "dmsProfiles"
    "cliproxyQuota"
    "commandRunner"
    "nixPackageRunner"
  ];
in
{
  # Deploy code only: DMS owns plugin settings/state and NixOS owns its service.
  xdg.configFile = lib.listToAttrs (
    map (
      name: lib.nameValuePair "DankMaterialShell/plugins/${name}" { source = plugins.${name}; }
    ) enabledPlugins
  );

  # Security/shell/media already supply bw, jq, wl-clipboard and capture tools.
  # KDE Connect (rather than Valent), Docker, Tailscale and Nix are system services/tools.
  home.packages = [
    pkgs.curl
    inputs.dankcalendar.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];
}

{ lib, pkgs, ... }:

{
  home.packages = with pkgs; [
    heroic
    hydralauncher
    lutris
    protonup-qt
    protonplus
    # Same wrapper trick as nixpkgs' programs.steam.protontricks: protontricks
    # runs outside Steam, so it does not see the STEAM_EXTRA_COMPAT_TOOLS_PATHS
    # that only Steam's own wrapper sets (see steam.nix). Without this it fails
    # with "Could not find configured Proton installation" for GE-Proton.
    (protontricks.override {
      extraCompatPaths = lib.makeSearchPathOutput "steamcompattool" "" [ proton-ge-bin ];
    })
    mangohud
    goverlay
    wineWow64Packages.stable
    winetricks
  ];

  # Alternative, not enabled: link GE-Proton where Steam and third-party tools
  # (Heroic, ProtonUp-Qt...) look for compatibility tools, so no variable is
  # needed. It is a workaround rather than the intended nixpkgs path, and tools
  # that look under ~/.steam/root need Steam to have run once to create it.
  # https://discourse.nixos.org/t/using-proton-ge-bin-package-outside-of-steam/77598
  #
  # home.file.".local/share/Steam/compatibilitytools.d/GE-Proton".source =
  #   pkgs.proton-ge-bin.steamcompattool;
}

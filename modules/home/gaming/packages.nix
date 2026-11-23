{ lib, pkgs, ... }:

{
  home.packages = with pkgs; [
    bottles
    heroic
    hydralauncher
    ludusavi
    lutris
    umu-launcher
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
    # DS4Windows-like tools: dualsensectl (LED, triggers, battery CLI), antimicrox (button remap).
    dualsensectl
    antimicrox
    # Gamepad polling rate testers (packages/gamepadla). gamepadla-plus is the CLI and GUI
    # fork and uploads only with --upload; gamepadla is the original and always uploads.
    gamepadla
    gamepadla-plus
    # Mouse polling rate tester (sudo evhz, or add yourself to the input group).
    evhz
    wineWow64Packages.stable
    winetricks
    # PlayStation Remote Play client. The global QT_STYLE_OVERRIDE=breeze makes its QML UI
    # fail to load ("module breeze is not installed") and the app exits silently, so unset
    # it for this app only.
    (symlinkJoin {
      name = "chiaki-ng";
      paths = [ chiaki-ng ];
      nativeBuildInputs = [ makeWrapper ];
      postBuild = "wrapProgram $out/bin/chiaki --unset QT_STYLE_OVERRIDE";
    })
  ];

  # umu-run outside Steam: PROTONPATH points it at the Nix-managed GE-Proton
  # instead of letting it download its own copy into ~/.local/share/umu.
  home.sessionVariables.PROTONPATH = "${pkgs.proton-ge-bin.steamcompattool}";

  # Alternative, not enabled: link GE-Proton where Steam and third-party tools
  # (Heroic, ProtonUp-Qt...) look for compatibility tools, so no variable is
  # needed. It is a workaround rather than the intended nixpkgs path, and tools
  # that look under ~/.steam/root need Steam to have run once to create it.
  # https://discourse.nixos.org/t/using-proton-ge-bin-package-outside-of-steam/77598
  #
  # home.file.".local/share/Steam/compatibilitytools.d/GE-Proton".source =
  #   pkgs.proton-ge-bin.steamcompattool;
}

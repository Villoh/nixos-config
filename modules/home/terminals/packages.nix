{ inputs, pkgs, ... }:

{
  home.packages = with pkgs; [
    yazi
    # Tools the Yazi config in chezmoi calls: archive previews and compression (ouch),
    # Markdown previews (glow), media previews (mediainfo), EXIF (reveal opener) and
    # browsing a KDE Connect phone (sshfs, used by kdeconnect.yazi).
    ouch
    glow
    mediainfo
    exiftool
    sshfs
    superfile
    nerd-fonts.jetbrains-mono
    # Logos of the herdr-agent-usage sidebar; Sheprd maps them via `[sidebar] fallback`.
    herdr-agent-icons

    # Modern workspaces under evaluation; keep the ones that stay and drop the rest.
    warp-terminal
    herdr-app
    # On PATH so Sheprd (its flake build bundles none) can start it for Herdr 2 terminals.
    herdr-core
    inputs.sheprd.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];
}

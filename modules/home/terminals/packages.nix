{ pkgs, ... }:

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
  ];
}

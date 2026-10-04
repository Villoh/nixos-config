{ pkgs, ... }:

let
  session = pkgs.writeShellScript "steam-gamescope" ''
    # Display managers need not source a login shell. Locate the logged-in
    # user's package profile, never another user's Steam installation.
    export PATH="/etc/profiles/per-user/$(${pkgs.coreutils}/bin/id -un)/bin:$HOME/.nix-profile/bin:$PATH"
    if ! command -v steam >/dev/null; then
      echo "Steam is not installed in this user's profile." >&2
      exit 1
    fi
    # PATH selects NixOS's wrapper, including configured flags/capabilities.
    exec gamescope --steam -- steam -tenfoot -pipewire-dmabuf
  '';
in
{
  programs.gamescope.enable = true;
  services.displayManager.sessionPackages = [
    (
      (pkgs.writeTextDir "share/wayland-sessions/steam.desktop" ''
        [Desktop Entry]
        Name=Steam (user profile)
        Comment=Gamescope session using the logged-in user's Steam
        Exec=${session}
        Type=Application
      '').overrideAttrs
        (_: {
          passthru.providedSessions = [ "steam" ];
        })
    )
  ];
}

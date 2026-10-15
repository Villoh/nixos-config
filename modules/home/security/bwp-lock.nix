{ ... }:

{
  # Locks the bwp session key on suspend and when DMS locks the screen.
  # The script itself is chezmoi-owned (~/.local/bin/bwp); this only runs it.
  systemd.user.services.bwp-lock-watch = {
    Unit.Description = "Lock the bwp Bitwarden session on suspend and screen lock";
    Service = {
      ExecStart = "%h/.local/bin/bwp watch";
      Environment = [ "PATH=/etc/profiles/per-user/%u/bin:/run/current-system/sw/bin" ];
      Restart = "on-failure";
      RestartSec = 5;
    };
    Install.WantedBy = [ "default.target" ];
  };
}

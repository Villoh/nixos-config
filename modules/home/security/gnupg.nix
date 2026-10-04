{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.gpg-agent;
in
{
  services.gpg-agent = {
    enable = true;
    enableSshSupport = true;
    pinentry.package = pkgs.pinentry-gnome3;
  };

  # chezmoi owns gpg-agent.conf, so select pinentry on the command line.
  # Keep HM's supervised mode, verbosity and GNUPGHOME service environment.
  systemd.user.services.gpg-agent.Service.ExecStart = lib.mkForce (
    "${config.programs.gpg.package}/bin/gpg-agent --supervised"
    + lib.optionalString cfg.verbose " --verbose"
    + lib.optionalString (!cfg.enableScDaemon) " --disable-scdaemon"
    + " --pinentry-program ${lib.getExe' cfg.pinentry.package cfg.pinentry.program}"
  );

  # GNOME pinentry needs GCR's prompt service outside a full GNOME session.
  home.packages = [ pkgs.gcr_3 ];
}

{ config, inputs, ... }:

# Noctalia, the alternative to DMS. Inert until a host sets
# `programs.noctalia.enable = true`; the settings and plugins live in
# modules/home/desktop/noctalia.nix. Switching shells, see docs/architecture.md.
{
  imports = [ inputs.noctalia.nixosModules.default ];

  programs.noctalia = {
    # NetworkManager, Bluetooth, UPower and power profiles: the Control Center tabs need them.
    recommendedServices.enable = true;
    # UWSM starts graphical-session.target for the compositor, same as DMS.
    systemd.enable = true;
  };

  # Always on, not gated by the enable: the cache must already be trusted by the running
  # system when the first build with Noctalia starts, or it compiles from source.
  nix.settings = {
    extra-substituters = [ "https://noctalia.cachix.org" ];
    extra-trusted-public-keys = [
      "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
    ];
  };

  # Two shells would fight over the notification bus name, the layer-shell surfaces and the lock.
  assertions = [
    {
      assertion = !(config.programs.noctalia.enable && config.programs.dms-shell.enable);
      message = "Noctalia and DMS cannot run together: set programs.dms-shell.enable = false in the host.";
    }
  ];
}

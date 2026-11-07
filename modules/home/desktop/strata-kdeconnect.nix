{
  inputs,
  lib,
  pkgs,
  ...
}:

# Strata's KDE Connect provider (Send to... > KDE Connect), registered declaratively.
#
# Alternative to the system python3 with PyGObject in modules/nixos/desktop/packages.nix.
# It uses a private python env that only provider.json references (no profile, no PATH).
# Strata rejects symlinked registrations, so the file is written for real on activation.
# It shows as "Manual" in Settings > Integrations (no Update button; it follows the
# strata flake input).
#
# To switch: drop the python3 line from modules/nixos/desktop/packages.nix and enable
# the import in ./default.nix. Then use Settings > Integrations > Refresh in Strata.

let
  providerPython = pkgs.python3.withPackages (ps: [ ps.pygobject3 ]);
  kdeconnectProvider = pkgs.writeText "provider.json" (
    builtins.toJSON {
      version = 1;
      id = "kdeconnect";
      name = "KDE Connect";
      category = "devices";
      command = [
        "${providerPython}/bin/python3"
        "${inputs.strata}/integrations/kdeconnect/provider.py"
      ];
    }
  );
in
{
  home.activation.strataKdeconnect = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run install -Dm644 ${kdeconnectProvider} "$HOME/.config/strata/providers/kdeconnect/provider.json"
  '';
}

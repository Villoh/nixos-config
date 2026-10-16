{ inputs, ... }:

# Opt-in per host, not part of core: the base must not need Home Manager.
# System-wide options only; each user's own profile lives under users/<name>.
{
  imports = [ inputs.home-manager.nixosModules.home-manager ];

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = { inherit inputs; };
    # Preserve pre-existing user files when Home Manager first takes ownership.
    backupFileExtension = "bak";
    # Apps (DMS, Brave, xdg-mime) rewrite files like mimeapps.list; Nix wins and
    # the last app-written version stays in <file>.bak instead of blocking activation.
    overwriteBackup = true;
  };
}

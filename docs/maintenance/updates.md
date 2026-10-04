# Update system and applications

Packages declared in NixOS or Home Manager change when you update the flake
inputs and rebuild the configuration. Do not update those packages manually:
change their version in the configuration when needed.

## Update flake inputs

From the repository root, first check which inputs will change:

```bash
cd /path/to/nixos-config
git status --short
nix flake update
git diff --stat
git diff -- flake.lock
```

`nix flake update` updates all inputs and saves the new versions in
`flake.lock`. To update only `nixpkgs`:

```bash
nix flake lock --update-input nixpkgs
```

Then validate and activate temporarily with [nh](nh.md):

```bash
nix flake check
nh os test . -H desktop
```

Verify graphical session, network, audio, Bluetooth, and Wayland portals. Only
after testing the result, apply it as the default generation:

```bash
nh os switch . -H desktop
```

Do not use `switch` to skip validation or testing. Review the diff before
applying changes; do not discard local changes that are not yours.

## Manual Nix profiles

`nix profile` installs packages outside NixOS and Home Manager. Use it only for
apps that are deliberately not declared in this repository. First see what
profiles contain:

```bash
nix profile list
```

Preview the upgrade of the current profile's packages before running it:

```bash
nix profile upgrade --all --dry-run
nix profile upgrade --all
```

Install manually only if declaring it is not appropriate:

```bash
nix profile install nixpkgs#hello
```

If `nix profile list` shows no entries, no apps were installed through that
profile. Upgrading the profile does not update the system configuration.

## Flatpak

Flatpak is updated separately from the flake:

```bash
flatpak update
```

See [Cleanup](cleanup.md) to remove unused Flatpak runtimes.

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

## Own packages (`packages/`)

Packages that are not in nixpkgs (or run ahead of it) live in `packages/<name>/package.nix`.
The flake exposes them as `packages.<system>.*` and, through `overlays.default`, as
`pkgs.<name>`. `nix flake update` does not touch them: their version is written in the
file. Update one with `nix-update`:

```bash
nix run nixpkgs#nix-update -- --flake tunnel-agent --build
git diff packages/
```

`nix-update` bumps `version` and every hash (source, pnpm, cargo) in one go. It follows
the newest stable release, even across major versions (strata 0.21 → 1.1 would be
applied unprompted), so read the upstream changelog first.

- `flectar-mail` only has alpha tags: add `--version=unstable`.
- `nix-update --flake` ignores the `extraArgs` of `passthru.updateScript` (only
  nixpkgs' own runner reads them), so such flags are never implicit.
- A matching hash does not prove the new version runs: build it and try it before `switch`.
- Not covered: `dms-bitwarden` (pinned on purpose, audited by hand).

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

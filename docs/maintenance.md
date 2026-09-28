# Maintenance

Procedures for updating, validating, and recovering the NixOS system.

## Update the system and declarative apps

Apps listed in NixOS/Home Manager update when flake inputs are updated and the
system is rebuilt:

```bash
cd /home/mikel/src/nixos-config
nix flake update
nix flake check
sudo nixos-rebuild test --flake .#desktop
```

`test` activates a temporary generation. Verify the graphical session, network,
audio, Bluetooth, and Wayland portals. If everything works, apply the generation:

```bash
sudo nixos-rebuild switch --flake .#desktop
```

Review changes before applying them:

```bash
git diff --stat
git diff -- flake.lock
```

Update only `nixpkgs`:

```bash
nix flake lock --update-input nixpkgs
```

## Apps installed with `nix profile`

`nix profile` manages manual installations outside `flake.nix` and Home
Manager. List installed packages:

```bash
nix profile list
```

Upgrade all packages:

```bash
nix profile upgrade --all
```

Preview an upgrade without changing anything:

```bash
nix profile upgrade --all --dry-run
```

Install an app manually:

```bash
nix profile install nixpkgs#hello
```

If `nix profile list` shows no entries, no apps are installed through this
method. For this repository, use the declarative flake update instead.

## Flatpak

Flatpaks update separately:

```bash
flatpak update
```

## Generations and rollback

List system generations:

```bash
sudo nix-env --list-generations --profile /nix/var/nix/profiles/system
```

If an update fails, boot an earlier generation from the systemd-boot menu. From
a TTY, fix the configuration and test again:

```bash
sudo nixos-rebuild test --flake .#desktop
```

Do not use `switch` until the test generation works.

## Store cleanup

Delete old generation data only after confirming that rollback generations are
no longer needed:

```bash
sudo nix-collect-garbage --delete-older-than 30d
```

systemd-boot keeps at most five entries through
`boot.loader.systemd-boot.configurationLimit`.

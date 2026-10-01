# `nh`: daily operations

`nh` is a CLI for common Nix, NixOS, and Home Manager tasks. In this
repository it is installed as a user package in
`modules/home/shell/packages.nix`. It is an interface for evaluating, building,
and activating the configuration; it does not change how the configuration is
declared or replace the flake.

When building, `nh` shows build progress and a diff of changes, and may ask for
confirmation before activating. The build still uses the configuration and
packages declared by the repository.

## Select this flake and host

The package is installed, but this repository does not set a default flake for
`nh`. Currently `flake.nix` declares only `desktop`; Zenbook is not a build
target until its hardware file is generated and the host is added to the flake.
Run commands from the checkout root and pass the path and host explicitly:

```bash
cd /home/mikel/src/nixos-config
nh os build . -H desktop
```

`-H desktop` selects `nixosConfigurations.desktop`; `.` identifies the flake in
the current directory. Always check that you are in the right checkout and host.

## Build, test, and activate

Pick the command based on the desired effect:

```bash
nh os build . -H desktop
nh os test . -H desktop
nh os switch . -H desktop
```

- `build`: builds without activating.
- `test`: activates the configuration in the running system, but does not make
  it the default for the next boot. Useful for testing and reverting with a
  reboot.
- `switch`: activates the configuration and sets it as the boot default.
  Requires administrative authorization.
- `boot`: builds and sets it as the boot default without immediately activating
  it in the current session.

After `test`, check graphical session, network, audio, Bluetooth, and Wayland
portals. If something fails, reboot or follow [Recovery](recovery.md). Run
`nix flake check` before building configuration changes. Do not use `switch`
until you have validated and tested changes.

## Other operations

```bash
nh os info
nh os rollback
nh search <package-name>
nh clean all --dry
```

`info` lists system profile generations; `rollback` builds and activates the
previous configuration. `search` queries packages. `clean` is described with
warnings and review steps in [Cleanup](cleanup.md). You can see available
options with `nh os --help` and `nh clean all --help`.

## Difference from `nixos-rebuild`

`nh os` offers a different interface and presentation, but the concepts are
still NixOS generations. Use `nixos-rebuild` if you need an option that `nh`
does not yet expose. For this host's workflows, both must point to the same
flake and host; do not mix a wrong path or host name.

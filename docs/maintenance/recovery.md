# Recovery and generations

NixOS keeps system generations so you can boot a previous version. This host
uses systemd-boot and keeps at most five entries, per
`boot.loader.systemd-boot.configurationLimit` in
`modules/nixos/core/boot.nix`. Store cleanup can remove old configurations:
do not run it while you depend on a generation to recover the system.

## Before activating a change

Validate the flake and activate temporarily, without making the configuration
the boot default yet:

```bash
nix flake check
nh os test . -H desktop
```

Check at least graphical login, network, audio, Bluetooth, and Wayland portals.
`test` helps detect activation failures; rebooting returns to the previous
generation. When tests pass, `nh os switch . -H desktop` activates the change
and sets the new boot generation. More detail in the [nh guide](nh.md).

## Graphical environment does not start

1. In the systemd-boot menu, select a previous generation.
2. If the system boots, fix the configuration in the checkout.
3. Run validation and a temporary test from a TTY:

```bash
cd /home/mikel/src/nixos-config
nix flake check
nh os test . -H desktop
```

4. Test the session and services again before applying a permanent change.

The previous generation restores access, but does not fix the source error. Do
not delete generations or run `switch` until the corrected configuration passes
tests.

## List or activate a previous generation

List system generations:

```bash
nh os info
```

The boot menu is the most conservative option: it selects a known generation
without changing the declarative configuration. If the system is running and you
need to revert the active one, `nh os rollback` activates the previous
generation. Confirm it is the desired generation and then fix or revert the
changes in the checkout; otherwise, the next deployment may reintroduce the
problem.

You can also list generations with Nix directly:

```bash
sudo nix-env --list-generations --profile /nix/var/nix/profiles/system
```

## Recovery from TTY

If the graphical environment fails but the system is still running, switch to a
TTY and check services and configuration. To test a fix without marking it as
the default:

```bash
cd /home/mikel/src/nixos-config
nix flake check
nh os test . -H desktop
```

If the test fails, review the build or activation error before retrying. Do not
use `switch` as a diagnostic method.

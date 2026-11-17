# Recovery and generations

NixOS keeps system generations so you can boot a previous version. This host
uses Lanzaboote (systemd-boot menu) and keeps at most five entries, per
`boot.lanzaboote.configurationLimit` in
`hosts/desktop/default.nix` (the Zenbook uses plain systemd-boot with the same limit).
Store cleanup can remove old configurations:
do not run it while you depend on a generation to recover the system.

## Before activating a change

Validate the flake and activate temporarily, without making the configuration
the boot default yet. Review `git diff` before activation:

```bash
nix flake check
nh os test . -H desktop
```

Check at least graphical login, network, audio, Bluetooth, and Wayland portals.
`test` helps detect activation failures; rebooting returns to the previous
generation. When tests pass, `nh os switch . -H desktop` activates the change
and sets the new boot generation. More detail in the [nh guide](nh.md).

## Boot fails with Secure Boot

If nothing boots after a bootloader or key change, disable Secure Boot in the firmware:
the signed entries still boot with it off. Do not clear the enrolled keys or `dbx`. See
[Secure Boot](../secure-boot.md#desktop-procedure-asus-rog-strix-x570-e) for the rollback.

## Graphical environment does not start

1. In the systemd-boot menu, select a previous generation.
2. If the system boots, fix the configuration in the checkout.
3. Run validation and a temporary test from a TTY:

```bash
cd /path/to/nixos-config
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

## Recovery from TTY

If the graphical environment fails but the system is still running, switch to a
TTY and check services and configuration. To test a fix without marking it as
the default:

```bash
cd /path/to/nixos-config
nix flake check
nh os test . -H desktop
```

If the test fails, review the build or activation error before retrying. Do not
use `switch` as a diagnostic method.

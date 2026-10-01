# Maintenance

Practical guides for updating, validating, deploying, recovering, and cleaning
this NixOS system. Each guide covers a separate workflow:

- [Update system and applications](maintenance/updates.md): update flake
  inputs, declarative apps, Tunnel Agent, manual profiles, and Flatpak.
- [`nh`: build and deploy](maintenance/nh.md): what `nh` does and how to use it
  in this repository.
- [Recovery and generations](maintenance/recovery.md): test changes, boot
  previous generations, and roll back.
- [Cleanup](maintenance/cleanup.md): review and clean generations, store roots,
  and Flatpak packages without losing rollback options.

## General rules

1. Review changes before applying them (`git diff`).
2. Run `nix flake check` after configuration or input changes.
3. Test system changes before making them permanent.
4. Keep old generations until you confirm the system works.
5. Do not run `nixos-rebuild switch` or destructive cleanup automatically.

## Host installation

- [Desktop installation](installation-desktop.md): existing `desktop` host.
- [Laptop installation](installation-laptop.md): guide to add `zenbook`.
  Requires generating its own hardware file and registering the host in
  `flake.nix` before it can be built or maintained with commands like `nh os`.

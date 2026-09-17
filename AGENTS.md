# AGENTS.md

## Repository purpose

This repository contains the reproducible NixOS configuration for the desktop
host, including hardware, system services, packages, Hyprland, DMS, and gaming
support.

## Repository conventions

- Use flakes and keep `flake.lock` committed and up to date.
- Keep host-specific configuration under `hosts/<host>/`.
- Keep reusable NixOS modules under `modules/`.
- Keep Home Manager modules under `home/`.
- Do not copy or modify a host's `hardware-configuration.nix` for another
  machine. A future host must have its own generated hardware configuration.
- Do not manage chezmoi-owned dotfiles, scripts, or secret templates through
  NixOS or Home Manager.
- Never commit secrets, passwords, private keys, tokens, or machine-local state.
- Prefer declarative Nix configuration over imperative installers or shell
  setup. Never use `curl | sh` installers.
- Avoid unrelated refactors and do not add placeholder modules without a use
  case.

## Safety rules

- Do not run `nixos-rebuild switch` or `boot` automatically.
- Do not change partitions, LUKS settings, boot loader settings, or generated
  hardware configuration without explicitly calling out the impact first.
- Use `nixos-rebuild test --flake .#desktop` for a temporary activation after
  validation. The user decides when to run `switch`.
- Do not delete configuration files or backups as part of routine work.
- Review `git diff` before applying a system generation.

## Validation

For Nix changes, run:

```bash
nix flake check
```

When available, format only the changed Nix files and do not reformat generated
hardware configuration. For system-level changes, recommend:

```bash
sudo nixos-rebuild test --flake .#desktop
```

Do not claim that a system change was applied unless the command actually ran
successfully.

## Git and commit conventions

Use [Conventional Commits](https://www.conventionalcommits.org/). Commit
messages must have the form:

```text
<type>(optional-scope): concise imperative description
```

Common types include:

- `feat`: add functionality
- `fix`: correct behavior
- `refactor`: restructure without changing behavior
- `docs`: documentation-only changes
- `chore`: maintenance, formatting, or dependency updates
- `build`: changes to the flake or build configuration

Examples:

```text
feat(gaming): add Steam and Proton-GE
fix(hyprland): enable Wayland portal support
docs: document rollback procedure
chore: update flake lock
```

Keep commits focused and do not mix unrelated changes. Do not create a commit
unless the user asks for one or explicitly approves it.

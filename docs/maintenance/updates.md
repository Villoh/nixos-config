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
the newest stable release, even across major versions, so read the upstream
changelog first.

- `flectar-mail` only has alpha tags: add `--version=unstable`.
- `nix-update --flake` ignores the `extraArgs` of `passthru.updateScript` (only
  nixpkgs' own runner reads them), so such flags are never implicit.
- A matching hash does not prove the new version runs: build it and try it before `switch`.
- `strata` is not here: upstream ships a flake, so it is the `strata` input and moves with
  `nix flake update strata`. It tracks `main` until a tagged release includes the flake.
- Not covered: `dms-bitwarden` (pinned on purpose, audited by hand).

## Prebuilt releases (`packages/prebuilt/`, temporary)

`arca`, `handy`, `hex`, `kopuz`, `sheprd`, `strata`, `wealthfolio`, `workmux`, `yapfast` and
`zapfast` are upstream's prebuilt Linux releases, named `<name>-bin`, because their source builds
compile locally (no binary cache yet). They are bumped like the packages above:

```bash
nix run nixpkgs#nix-update -- --flake workmux-bin --build
```

Each module line that uses one carries a `PENDING: cache` comment next to the original
source-built line (the flake input stays in `flake.nix`, so it is still pinned in
`flake.lock`). `handy`, `hex` and `wealthfolio` are swapped in the overlay and in
`packages/default.nix`, so `pkgs.handy`, `pkgs.hex` and `pkgs.wealthfolio` keep working.
Once a binary cache serves the source builds, revert those lines and delete
`packages/prebuilt/`. A release can lag the flake input (it is built from `main`), so
check the version before assuming they match.

`strata-bin` has no RAR support (the official release omits UnRAR) and is built for Arch: it
finds ffmpeg, ffmpegthumbnailer, imagemagick, bubblewrap and the other helpers only in system
directories, so they are in `environment.systemPackages`. Its update marker (`install-source.toml`)
is installed by the package, and the in-app updater and runtime integrations are compile-time
switches that stay on. Reverting to the source build means restoring the `callPackage` lines in
`modules/home/desktop/packages.nix` and `modules/nixos/desktop/portals.nix` and removing the
helpers.

`kopuz-bin` is the GPUI nightly (the stable release is still the old WebKit app). It is a
separate channel (`*-nightly` binaries, `moe.kopuz.kopuz.nightly`, `kopuzd-nightly.sock`), so it
does not share the stable app's socket. Bump it with `nix-update --flake kopuz-bin
--version=unstable`; the tags are `v0.68.0-nightly.YYYYMMDD[.N]`.

## Package formats: flake, binary or Flatpak

An app outside nixpkgs reaches the system in one of three ways:

- **Flake (source)**: a flake input or `packages/<name>/package.nix` that builds from source.
  Pinned by `flake.lock`, patchable, but it compiles here unless a binary cache serves it.
  The flake can also expose a prebuilt output (Sonora's `sonora-bin`).
- **Binary**: upstream's release repackaged under `packages/` (see above). Nothing compiles;
  version and hash are bumped by hand.
- **Flatpak**: declared in `services.flatpak.packages` (nix-flatpak). Nothing compiles and
  nothing enters the Nix store or a Nix cache, it installs at activation and updates with
  `flatpak update`. It is as opaque as a binary: no overrides or patches, plus a sandbox.

Legend: yes = available, no = not available, `?` = not checked. "Current" is what the
configuration installs today. Release availability was checked on 2026-11-08.

| Package | Flake (source) | Binary | Flatpak | Current |
|---|---|---|---|---|
| workmux | yes (364 crates) | yes (tar.gz) | no | Binary |
| zapfast | yes (864 crates) | yes (tar.gz) | yes (release bundle, app ID not checked) | Binary |
| arca | yes (477 crates) | yes (tar.gz) | no | Binary |
| yapfast | yes (about 10 min measured) | yes (pkg.tar.zst) | no | Binary |
| sheprd | yes (1,177 crates) | yes (tar.gz) | no | Binary |
| hex | yes (767 crates) | yes (.deb) | no | Binary |
| handy | nixpkgs, 0.9.6 plus a local patch | yes (.deb) | no | Binary |
| wealthfolio | nixpkgs, and `packages/wealthfolio` | yes (.deb) | no | Binary |
| kopuz | yes (about 2,200 derivations) | nightly only (GPUI, same commit as the lock); the stable release is the legacy WebKit app | Flathub 0.67.1 is the legacy Dioxus app (`dx build`), not GPUI | Binary (nightly) |
| sonora | yes (`sonora-src`) | yes, `sonora-bin` in the same flake | yes (official repo) | Flake, binary output |
| meiro | no (Bazel) | yes (minimal tarball, `packages/meiro`; ffmpeg, yt-dlp and Node from nixpkgs) | yes (release bundle; sign-in needs `--talk-name=org.freedesktop.Flatpak`) | Binary |
| strata | yes (442 crates, `rarSupport = true`) | yes (tar.gz), but the official release omits non-free UnRAR and embeds no Nix store paths | no | Binary (no RAR); its helpers are in `environment.systemPackages` |
| dankcalendar | yes (Go) | yes (`dcal`) | no | Flake |
| himalaya-tui | yes (482 crates) | no | no | Flake |
| nixup | yes (own flake) | no | no | Flake |
| serein | yes (input kept, 764 derivations, host build disabled until a cache and #905) | ? | yes (own repo) | Flatpak: the sandbox gives it the app ID that global shortcuts need (ViceVerse-cz/Serein#905) |
| hylki | no official flake; community `clementpoiret/hylki-flake` builds it from source | yes (`.deb` 11 MiB, `.rpm`, AppImage; native Rust and GTK4 app) | yes (own `.flatpakref`, GNOME 50 runtime) | Flatpak |
| flectar-mail | no (no flake found, not in nixpkgs) | yes (`.deb` 33 MiB with a native binary and `libpdfium`, AppImage, `.rpm`) | yes (release bundle, `packages/flectar-mail`) | Flatpak |
| rustdesk | nixpkgs, legacy Sciter UI | ? | yes (Flathub) | Flatpak: nixpkgs lacks the login the public server needs |
| cherry-studio | nixpkgs, 1.9.11 on EOL Electron | ? | yes (Flathub) | Flatpak: Flathub tracks 2.x |

"Crates" is the size of the project's `Cargo.lock`, a rough proxy for compile cost. Only
yapfast (about 10 minutes) and kopuz (2,184 derivations) were measured.

Rule of thumb: flake when compiling is cheap or the app needs patches or options; binary
when the flake is expensive and the app needs no deep host integration; Flatpak only with an
official repo, no host integration and no wish to pin it from the flake.

### Other third-party apps (current format only, alternatives not checked)

| Package | Current format | Source |
|---|---|---|
| ytm-player | Flake | `ytm-player` input |
| zen-browser | Flake, upstream tarball repackaged | `zen-browser` input (overridden in `browsers.nix`) |
| helium-browser | Flake, `.deb` repackaged | `helium-browser` input |
| claude-desktop | Flake, official `.deb` repackaged | `llm-agents` input |
| t3code-desktop | Flake | `llm-agents` input |
| codex-desktop | Flake (Home Manager module) | `codex-desktop-linux` input |
| holded-tt, goopdl, masamune | Flake, own tools | `holded-tt`, `goopdl`, `masamune` inputs |
| omarchy-dms | Flake, own tool | `omarchy-dms` input |
| waydroid-nvidia | Flake, community packaging | `waydroid-nvidia-nix` input |
| lanzaboote | Flake (NixOS module) | `lanzaboote` input |
| tunnel-agent | Binary, AppImage | `packages/tunnel-agent` |
| herdr-core, herdr-app | Binary, upstream tarball (hosted outside GitHub) | `packages/herdr-*` |
| herdr-agent-icons | Binary, a single font file | `packages/herdr-agent-icons` |
| filen-desktop | nixpkgs source, patched in the overlay | `modules/nixos/core/nix.nix` |

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

# Update system and applications

Packages declared in NixOS or Home Manager change when you update the flake
inputs and rebuild the configuration. Do not update those packages manually:
change their version in the configuration when needed.

Updates go through [nixup](https://github.com/Villoh/nixup), itself a flake input. It
covers four sources: flake inputs, the packages in `packages/`, Flatpak and `nix profile`.

## See what is pending

```bash
nixup check            # everything outdated, one table
nixup check --all      # up-to-date rows too
nixup check nixpkgs    # one name
```

Rows marked `major` are likely breaking jumps: read the upstream notes first. A weekly
GitHub issue (`.github/workflows/updates.yml`) lists the same table and opens a new
issue only when a name appears that was not pending before.

## Update

```bash
nixup update                        # everything, asking before each step
nixup update nixpkgs home-manager   # only these names
nixup update --test                 # then nh os test on the host
```

For each input that moved, `update` shows the upstream commits and release notes, asks,
and writes `flake.lock`. For each package it shows the same review, asks, runs nix-update
pinned to that version and builds the package; a failed build restores its files.
nixup never commits.

- `--build` also builds the host in a scratch copy before writing `flake.lock`, with nh's
  diff of what changes. `--test`, `--switch` and `--boot` imply it, then run `nh os
  <verb>`. Without them, a `flake.lock` that does not build is only found at `nh os test`.
- `--source input,package` leaves Flatpak and `nix profile` alone (both install on yes).
- `--report <file>` writes the review as Markdown.

Then validate and activate with [nh](nh.md), unless `--test` already did:

```bash
nix flake check
nh os test . -H desktop
```

Verify graphical session, network, audio, Bluetooth, and Wayland portals. Only
after testing the result, apply it as the default generation. When the kernel or the
NVIDIA driver changes, use `boot` and reboot instead of `switch`: a running system would
keep the old module next to the new libraries.

```bash
nh os switch . -H desktop   # or: nh os boot . -H desktop && reboot
```

Do not use `switch` to skip validation or testing. Review the diff before
applying changes; do not discard local changes that are not yours.

## Flake inputs

Inputs that publish releases are pinned to their tag in `flake.nix`
(`github:owner/repo/v1.2.1`): `nixup check` shows their version, and `nixup update <name>`
moves the tag and asks first when the jump is likely breaking. The rest follow a
branch, and the table shows the locked commit and its age.

- `goopdl`, `holded-tt`, `masamune`, `nixup`, `omarchy`, `omarchy-dms`, `sonora`, `strata`,
  `ytm-player`, `dms` and `lanzaboote` are tags.
- `dms` provides only Dux Shell's HM module; the shell is nixpkgs' `dux-shell`. Its
  `# nixup: follows nixpkgs#dux-shell` marker makes nixup move the tag to nixpkgs'
  version (after `nixup update nixpkgs`), and show a newer upstream tag only as `info`.
- `himalaya-tui` keeps its own nixpkgs (nixos-25.11), the one upstream tests: with unstable's
  `cargoSetupHook` its `-sys` crates need libraries its derivation does not list.
- Noctalia's plugin inputs are trusted Luau code: review their diff before updating them.

## Own packages (`packages/`)

Packages that are not in nixpkgs (or run ahead of it) live in `packages/<name>/package.nix`.
The flake exposes them as `packages.<system>.*` and, through `overlays.default`, as
`pkgs.<name>`. `nix flake update` does not touch them: their version is written in the
file, and `passthru.updateScript` says how nix-update finds the next one. nixup reads
those flags, so `nixup update <name>` follows the same rules:

- `--url https://github.com/<owner>/<repo>`: versions come from that repository's tags
  (herdr-app, herdr-core and the prebuilt releases hosted outside GitHub).
- `--use-github-releases`: published releases instead of tags (google-sans-flex, kopuz-bin).
- `--version=unstable`: prereleases count (flectar-mail, kopuz-bin, serein-bin).
- `--version-regex`: one tag series out of several (meiro's `desktop-v*`).
- `passthru.nixup.versionUrl`: a URL that serves the latest version, for a project whose
  GitHub tags mix release channels (none here now; brave-origin used it while it was out
  of nixpkgs).
- `passthru.nixup.pinned`: kept where it is on purpose (herdr-agent-icons).

A matching hash does not prove the new version runs: build it and try it before `switch`.
Not covered: `dms-bitwarden` (pinned on purpose, audited by hand).

## Temporary nixpkgs workarounds

None right now. When nixpkgs breaks a package you use, override it where it is used, with
a `PENDING` comment naming the nixpkgs fix, and remove it once that fix reaches
nixos-unstable (the channel moves only after Hydra builds the commit). An overridden
package is never in cache.nixos.org, so it compiles here: prefer an override that applies
only while the package still lacks the fix and warns once it is there, as was done for
rustdesk-flutter when `cargoSetupHook` started forcing Rust `-sys` crates onto system
libraries (nixpkgs 44cddf9, 2026-10-12).

## Prebuilt releases (`packages/prebuilt/`, temporary)

`arca`, `aube`, `handy`, `hex`, `kopuz`, `serein`, `sheprd`, `strata`, `wealthfolio`, `workmux`
and `yapfast` are upstream's prebuilt Linux releases, named `<name>-bin`, because their source builds
compile locally (no binary cache yet). They are bumped like the packages above, with
`nixup update workmux-bin`.

Each module line that uses one carries a `PENDING: cache` comment next to the original
source-built line (the flake input stays in `flake.nix`, so it is still pinned in
`flake.lock`). `aube` and `wealthfolio` also have a source package (`packages/aube`,
`packages/wealthfolio`, copied from nixpkgs, which runs behind upstream), commented out in
`packages/default.nix` until then. `handy` and `hex` are swapped in the overlay, so `pkgs.handy`
and `pkgs.hex` keep working; the modules use the other `-bin` packages by their own name.
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
does not share the stable app's socket. Its tags are `v0.68.0-nightly.YYYYMMDD[.N]`.

`serein-bin` is the nightly Arch package (upstream publishes only pre-releases, tagged
`v1.0.0-nightly.YYYYMMDD.N`), so it moves with Serein's `main` branch. The Flatpak is
not an option: its PID namespace makes Serein hand Hyprland a sandbox PID, so the tray hide
never finds the window. Global shortcuts need a build with ViceVerse-cz/Serein#906; they
register as `cz.viceverse.serein:toggle-mute` and `:toggle-deafen`. After an update,
log in again only if the profile moved: the host build keeps its data in
`~/.local/share/serein`, not in the Flatpak's.

## Package formats: flake, binary or Flatpak

An app outside nixpkgs reaches the system in one of three ways:

- **Flake (source)**: a flake input or `packages/<name>/package.nix` that builds from source.
  Pinned by `flake.lock`, patchable, but it compiles here unless a binary cache serves it.
  The flake can also expose a prebuilt output (Sonora's `sonora-bin`).
- **Binary**: upstream's release repackaged under `packages/` (see above). Nothing compiles;
  `nixup update` bumps version and hash.
- **Flatpak**: declared in `services.flatpak.packages` (nix-flatpak). Nothing compiles and
  nothing enters the Nix store or a Nix cache, it installs at activation and updates with
  `flatpak update`. It is as opaque as a binary: no overrides or patches, plus a sandbox.

Legend: yes = available, no = not available, `?` = not checked. "Current" is what the
configuration installs today. Release availability was checked on 2026-11-08.

| Package | Flake (source) | Binary | Flatpak | Current |
|---|---|---|---|---|
| workmux | yes (364 crates) | yes (tar.gz) | no | Binary |
| zapfast | yes (864 crates), and nixpkgs (cached) | yes (tar.gz) | yes (release bundle, app ID not checked) | nixpkgs |
| arca | yes (477 crates) | yes (tar.gz) | no | Binary |
| yapfast | yes (about 10 min measured) | yes (pkg.tar.zst) | no | Binary |
| sheprd | yes (1,177 crates) | yes (tar.gz) | no | Binary |
| hex | yes (767 crates) | yes (.deb) | no | Binary |
| handy | nixpkgs, 0.9.6 plus a local patch | yes (.deb) | no | Binary |
| wealthfolio | nixpkgs, and `packages/wealthfolio` | yes (.deb) | no | Binary |
| aube | nixpkgs (1.32, behind), and `packages/aube` (2.10, builds with 4 sandbox tests skipped) | yes (static musl tar.gz) | no | Binary |
| kopuz | yes (about 2,200 derivations) | nightly only (GPUI, same commit as the lock); the stable release is the legacy WebKit app | Flathub 0.67.1 is the legacy Dioxus app (`dx build`), not GPUI | Binary (nightly) |
| sonora | yes (`sonora-src`) | yes, `sonora-bin` in the same flake | yes (official repo) | Flake, binary output |
| meiro | no (Bazel) | yes (minimal tarball, `packages/meiro`; ffmpeg, yt-dlp and Node from nixpkgs) | yes (release bundle; sign-in needs `--talk-name=org.freedesktop.Flatpak`) | Binary |
| strata | yes (442 crates, `rarSupport = true`) | yes (tar.gz), but the official release omits non-free UnRAR and embeds no Nix store paths | no | Binary (no RAR); its helpers are in `environment.systemPackages` |
| dux-calendar | nixpkgs module (`programs.dux-calendar`) | yes (`dcal`) | no | nixpkgs |
| himalaya-tui | yes (482 crates) | no | no | Flake |
| nixup | yes (own flake) | no | no | Flake |
| serein | yes (764 derivations; needs a rev with ViceVerse-cz/Serein#906 for global shortcuts) | nightly only (all releases are pre-releases; Arch `pkg.tar.zst`) | yes (own repo), but its PID namespace breaks the tray hide: Serein sends Hyprland its sandbox PID | Binary (nightly) |
| hylki | no official flake; community `clementpoiret/hylki-flake` builds it from source (186 derivations) | yes (`.deb` 12 MiB, `.rpm`, AppImage; native Rust and GTK4 app), tested and working | yes (own `.flatpakref`, GNOME 50 runtime) | Flatpak: no problems so far; the flake is the goal once a private cache exists, the binary adds nothing over the Flatpak |
| flectar-mail | no (no flake found, not in nixpkgs) | yes (`.deb` 33 MiB with a native binary and `libpdfium`, AppImage, `.rpm`) | yes (release bundle, `packages/flectar-mail`) | Flatpak |
| rustdesk | nixpkgs `rustdesk` is the legacy Sciter UI; `rustdesk-flutter` is the current UI | yes (`.deb`, AppImage) | yes (Flathub) | nixpkgs `rustdesk-flutter` |
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
| zen-browser | Flake, upstream tarball repackaged | `zen-browser` input (wrapped with prefs in `browsers.nix`) |
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
| filen-desktop | nixpkgs | `modules/home/cloud/packages.nix` |

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
profile. Upgrading the profile does not update the system configuration. `nixup update`
covers it too, as its last step.

## Flatpak

Flatpak is updated separately from the flake, with `nixup update --source flatpak` (it
shows what would change and prints how to roll each ref back) or directly:

```bash
flatpak update
```

See [Cleanup](cleanup.md) to remove unused Flatpak runtimes.

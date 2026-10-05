# Generation and disk space cleanup

Nix keeps every derivation needed by active profiles and configurations in
`/nix/store`. Garbage collection deletes only paths that are no longer
reachable from profiles or GC roots; it does not delete active dependencies.
Old generations are kept as roots for rollback, so you must first remove them
from profiles and then collect the store.

On this host, systemd-boot keeps up to ten entries. `nh clean all` cleans
system and user profiles, collects the store, and also checks GC roots. By
default it may remove build-result and direnv roots. Read the preview before
running it.

## Review before cleaning

Check which generations you want to keep:

```bash
nh os info
nix profile list
```

The first command lists system generations. The second shows the current
user's profile packages; it is not equivalent to a list of NixOS generations.
Boot the system and test pending changes before removing old configurations.

## Recommended cleanup

First preview cleanup of all profiles, keeping at least ten generations and
all generations/roots from the last 30 days:

```bash
nh clean all --keep 10 --keep-since 30d --dry
```

Review which profiles, generations, and roots it proposes to delete. If the
list would delete a rollback you need, stop or adjust retention. To perform the
cleanup, run the command again without `--dry`:

```bash
nh clean all --keep 10 --keep-since 30d
```

`--keep` is a minimum by count and `--keep-since` keeps by age; more than ten
generations may remain. The values are retention, not a target to delete
everything older. Keep several generations and avoid cleaning while diagnosing
a failure.

## Temporary roots and direnv

`nh clean all` also removes stale indirect roots. This can remove `result`
symlinks from builds and direnv project roots, so the store may be collected if
no other reference remains. To keep direnv roots:

```bash
nh clean all --keep 10 --keep-since 30d --no-direnv --dry
```

`--no-gcroots` disables cleanup of all GC roots. Use that option if you want to
collect generations and the store without touching temporary roots. See
`nh clean all --help` for available flags and use dry-run before making
changes.

## Optimise store

`--optimise` deduplicates identical files in the store to reduce disk usage. It
does not remove additional versions or generations; it is a separate step from
collection and can take a while. Check the cleanup plan first, then you can
include optimisation:

```bash
nh clean all --keep 10 --keep-since 30d --optimise --dry
nh clean all --keep 10 --keep-since 30d --optimise
```

Do not use `--delete-current` as routine cleanup: it allows removing the
selected generation and can leave the profile link dangling.

## Flatpak

Flatpak keeps apps and runtimes outside the Nix store. Update them separately:

```bash
flatpak update
```

To remove unused runtimes, review the list and let Flatpak confirm deletions:

```bash
flatpak list --runtime
flatpak uninstall --unused
```

There is no NixOS rollback for Flatpak removal; the app or runtime may need to
be downloaded again.

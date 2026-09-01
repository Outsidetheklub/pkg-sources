# pkg-sources

**Show where your installed software comes from.** Every package on your
system, classified by origin — pacman repos, AUR, local builds, Flatpak,
and Snap. Built for Arch Linux.

```
$ pkg-sources --count

SOURCE                   COUNT
------------------------ -----
AUR                      20
flatpak [flathub]        13
local                    5
pacman [cidercollective] 1
pacman [core]            209
pacman [extra]           1122
pacman [multilib]        84

TOTAL                    1455
```

## Features

- **Full inventory** — every installed package, not just GUI apps
- **Accurate AUR detection** — foreign packages are verified against the
  [AUR RPC API](https://aur.archlinux.org/rpc/) in **batched requests**
  (500 names per call), so it's fast even with hundreds of AUR packages
  and needs no per-package `paru`/`yay` round-trips
- **Custom repo awareness** — `pacman [cidercollective]` shows up just
  like `pacman [core]`; any repo in your sync DB is detected
- **Flatpak + Snap** — apps listed with their remote (`flathub`, ...)
- **GUI mode** — the original `.desktop`-based view, now with versions
- **Multiple output formats** — grouped report, per-source filter, counts,
  or JSON for scripting

## Requirements

- Arch Linux (uses `pacman`)
- `curl` + `jq` for AUR verification (falls back gracefully if missing)
- `flatpak` / `snap` only needed if you use those

## Installation

```sh
install -m755 pkg-sources ~/.local/bin/pkg-sources
```

Or just run it in place: `./pkg-sources`

## Usage

```
pkg-sources                 full inventory, grouped by source
pkg-sources --gui           only apps with a .desktop launcher
pkg-sources --aur           only AUR packages
pkg-sources --source extra  only packages from a given source
                            (case-insensitive substring:
                            extra, aur, flathub, cidercollective, ...)
pkg-sources --count         summary: how many packages per source
pkg-sources --json          machine-readable output (JSON array)
pkg-sources --no-aur-check  skip the AUR API lookup (offline use)
```

### Example output

```
$ pkg-sources --source flathub

== flatpak [flathub] (13) ==
  Discord                                  1.0.155
  Fedora Media Writer                      5.3.2
  LocalSend                                1.18.2
  Telegram                                 5.11.0
  ...
```

```
$ pkg-sources --gui

== AUR (5) ==
  Bottles                                  2:66.9-1
  Brave Origin                             1:1.94.117-1
  Quickshell                               0.3.1.r10.g2d3b3e9-1

== pacman [extra] (84) ==
  Firefox                                  132.0-1
  VLC media player                         3.0.21-9
  ...
```

```
$ pkg-sources --json | jq '.[] | select(.source == "AUR")'

{
  "name": "quickshell-git",
  "version": "0.3.1.r10.g2d3b3e9-1",
  "source": "AUR"
}
```

## How it works

1. `pacman -Sl` builds a package → repo map from your sync databases
   (one call, no network).
2. `pacman -Qn` / `pacman -Qm` list native and foreign packages.
3. Foreign packages are batch-verified against the AUR RPC API —
   found = `AUR`, not found = `local` (manual builds, private PKGBUILDs).
4. `flatpak list` and `snap list` add app sources with their remotes.
5. In `--gui` mode, `.desktop` files are matched to owners via
   `pacman -Qo` and the sources above.

## Source classification

| Source                 | Meaning                                              |
|------------------------|------------------------------------------------------|
| `pacman [core]`        | Official repo (any repo in your sync DB works)       |
| `AUR`                  | In the Arch User Repository                          |
| `local`                | Foreign, **not** in the AUR (manual/private builds)  |
| `flatpak [flathub]`    | Flatpak app from a remote (shows its name)           |
| `snap`                 | Snap package                                        |
| `foreign (unverified)` | Foreign pkg when AUR check skipped / unavailable     |

## License

MIT — see [LICENSE](LICENSE).

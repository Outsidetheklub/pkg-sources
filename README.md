# pkg-sources

Shows where every package on your Arch system came from — pacman repos,
AUR, local builds, Flatpak, or Snap. Works on any Arch-based distro
(Arch, EndeavourOS, Manjaro, CachyOS, ...).

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

## Install

**Option 1 — one-liner (just the script):**

```sh
curl -fsSL https://raw.githubusercontent.com/Outsidetheklub/pkg-sources/main/pkg-sources \
  -o ~/.local/bin/pkg-sources && chmod +x ~/.local/bin/pkg-sources
```

**Option 2 — clone the repo (get updates, README, license):**

```sh
git clone https://github.com/Outsidetheklub/pkg-sources
cd pkg-sources
./pkg-sources
```

Either way, `~/.local/bin` should be on your `PATH` (it is by default on
Arch). Or just run it in place: `./pkg-sources`

## Usage

```
pkg-sources                 full inventory, grouped by source
pkg-sources --gui           only apps with a .desktop launcher
pkg-sources --aur           only AUR packages
pkg-sources --source extra  only packages from a given source
                            (extra, aur, flathub, cidercollective, ...)
pkg-sources --count         summary per source
pkg-sources --json          JSON output (pipe to jq)
pkg-sources --no-aur-check  skip AUR lookup (offline)
```

## Notes

- Foreign packages are checked against the AUR API in batches — found =
  `AUR`, not found = `local` (manual builds, private PKGBUILDs).
- Needs `curl` and `jq` for the AUR check; falls back gracefully if missing.
- Flatpak and Snap are only included if you have them installed.

## License

MIT

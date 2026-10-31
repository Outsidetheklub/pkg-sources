# pkg-sources

Shows where every package on your system came from — without assuming a distro.
It detects which package managers are installed and reports whichever answer,
so the same script works on Arch and Debian:

| manager | classified as |
| --- | --- |
| pacman | `pacman [repo]` (core, extra, custom repos…), `AUR`, `local` |
| apt | `apt [<repo host/suite>]` for archive packages, `apt [<host>]` for third-party repos, `apt [local]` for hand-installed `.deb` |
| flatpak | `flatpak [remote]` |
| snap | `snap` |

A package manager that is not installed produces no section at all — there is
no Arch build and no Debian build, and you never see an empty manager listed.

By default it lists **explicitly installed** packages only. A dependency is not
something you chose, and on a normal Debian box it is most of the install
(1238 → 285 here). `--all` brings the dependencies back, `--dep` shows only them.

```
$ pkg-sources --count

SOURCE                   COUNT
------------------------ -----
apt [deb.debian.org/trixie] 277
apt [developer.download.nvidia.com] 2
apt [download.opensuse.org] 1
apt [security.debian.org/trixie-security] 1
flatpak [flathub]        4

TOTAL                    285
```

With `--all`, the same machine:

```
apt [deb.debian.org/trixie] 1179
apt [developer.download.nvidia.com] 50
apt [download.opensuse.org] 1
apt [security.debian.org/trixie-security] 4
flatpak [flathub]        4

TOTAL                    1238
```

On Arch the sections read `pacman [core]`, `pacman [extra]`, `AUR`, `local`…

## Install

**Clone the repo — the script needs `backends/` beside it:**

```sh
git clone git@github.com:Outsidetheklub/pkg-sources.git ~/pkg-sources
~/pkg-sources/pkg-sources
```

> ⚠️ The old one-liner that downloaded only `pkg-sources` no longer works: the
> apt support lives in `backends/apt.sh`, and a lone script silently reports
> flatpak/snap only (4 packages instead of 285). If you have one from an older
> version, replace it with a launcher that execs the checkout.

Put it on `PATH` yourself, or symlink it:

```sh
ln -sf ~/pkg-sources/pkg-sources ~/.local/bin/pkg-sources
```

`~/.local/bin` is on `PATH` in most setups; for bash/zsh add
`export PATH="$HOME/.local/bin:$PATH"`, for fish run `fish_add_path ~/.local/bin`.

## Usage

```
pkg-sources                 explicitly installed packages (default)
pkg-sources --all           everything, dependencies included
pkg-sources --dep           only packages installed as dependencies
pkg-sources --no-dep        only explicit installs (same as the default)
pkg-sources --gui           only apps with a .desktop launcher
pkg-sources --aur           only AUR packages (Arch only)
pkg-sources --source WORD   only matching sources, substring:
                            extra, aur, flathub, nvidia, trixie, …
pkg-sources --count         summary per source
pkg-sources --json          JSON output (pipe to jq)
pkg-sources --no-aur-check  skip the AUR lookup (offline)
```

Flags that need an absent backend fail loudly instead of returning nothing —
`--aur` on Debian exits 1 with an explanation.

## How each backend finds the origin

- **pacman** — repo map from `pacman -Sl`; native packages from `pacman -Qn`;
  foreign ones (`pacman -Qm`) verified against the AUR RPC API in batches of
  500. Anything foreign that the AUR does not know is `local`.
- **apt** — one pass over `/var/lib/apt/lists/*_Packages`; the list *filename*
  encodes the origin (`deb.debian.org_debian_dists_trixie_main_…`), so the host
  is everything before the first `_`. `explicit` comes from
  `apt-mark showmanual`, and `${db:Status-Abbrev}` keeps removed-but-conffiles
  packages out of the count.
- **flatpak / snap** — straight from their own listings, always explicit.

## Performance

The point is to never pay a process start per package:

- apt: 1235 packages in **0.19 s** (a per-package `apt-cache policy` loop is
  roughly 100× slower for the same answer)
- pacman: **2.6 s** full inventory, **2.5 s** with `--gui`, after batching
  `-Qm` and `-Qo` into single calls

## Notes

- The AUR check needs `curl` and `jq`; without them foreign packages show as
  `foreign (unverified)` instead of `AUR`/`local`.
- `--gui` resolves .desktop ownership in one bulk call (`pacman -Qo` or
  `dpkg -S`). Flatpak exports are symlinks, which is why the file scan accepts
  symlinks as well as regular files.
- Known gap: on a duplicate package name across repos, the first apt list read
  wins. Preferring the entry whose version matches the installed one is the fix.

## License

MIT

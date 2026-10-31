#!/usr/bin/env bash
#
# apt backend for pkg-sources  (Debian / Ubuntu and derivatives)
#
# Not a standalone script: source it, then call `collect_apt`. It prints one
# normalised row per installed package, TAB separated:
#
#     name <TAB> version <TAB> source <TAB> kind <TAB> explicit
#
#   source    the repository it came from — "deb.debian.org/trixie",
#             "security.debian.org/trixie-security", "developer.download.nvidia.com",
#             "download.opensuse.org", or "local" when no apt list knows the package
#   kind      repo | third-party | manual
#   explicit  y = apt-mark calls it manually installed, n = pulled in as a dependency
#             (the apt equivalent of pacman's "installed as dependency")
#
# Cost: ONE pass over /var/lib/apt/lists/*_Packages — 59 MB and 0.19 s for
# 1235 installed packages on a Debian 13 desktop (2026-10-31). Do NOT loop over
# `apt-cache policy` per package; that is ~100x slower for the same answer.
#
# The apt list filename encodes the origin:
#   deb.debian.org_debian_dists_trixie_main_binary-amd64_Packages
#   download.opensuse.org_repositories_isv:_BrowserWorks_Debian%5f13_Packages
# so the host is everything before the first underscore, and the suite (when
# present) follows "_dists_".
#
# TODO before the JSON/GUI layers rely on this: on a duplicate package name the
# first list read wins. Prefer the entry whose Version matches the installed one.

_apt_lists_cat() {
    # Debian ships these uncompressed; other repos/distros may not.
    case "$1" in
        *.lz4) command -v lz4 >/dev/null 2>&1 && lz4 -dc "$1" ;;
        *.gz)  gzip -dc "$1" ;;
        *)     cat "$1" ;;
    esac
}

collect_apt() {
    _tmp="${TMPDIR:-/tmp}/pkg-sources-apt.$$"
    : > "$_tmp"
    for f in /var/lib/apt/lists/*_Packages; do
        [ -e "$f" ] || continue
        base="${f##*/}"
        host="${base%%_*}"
        case "$base" in
            *_dists_*) suite="${base#*_dists_}"; suite="${suite%%_*}"; src="$host/$suite" ;;
            *)         src="$host" ;;
        esac
        _apt_lists_cat "$f" | awk -v src="$src" '
            /^Package: / { p = $2 }
            /^Version: / { if (p != "" && !(p in seen)) { print p "\t" $2 "\t" src; seen[p] = 1 } }
            /^$/ { p = "" }
        ' >> "$_tmp"
    done

    apt-mark showmanual 2>/dev/null | sort > "$_tmp.manual"
    # ${db:Status-Abbrev} keeps removed-but-conffiles packages from being
    # reported as installed; a plain `dpkg -l` parse gets that wrong.
    dpkg-query -W -f='${db:Status-Abbrev} ${Package} ${Version}\n' 2>/dev/null |
    awk -v map="$_tmp" -v man="$_tmp.manual" '
        BEGIN {
            while ((getline line < map) > 0) {
                split(line, a, "\t")
                if (!(a[1] in repo)) repo[a[1]] = a[3]
            }
            while ((getline m < man) > 0) manual[m] = 1
        }
        $1 ~ /^ii/ {
            name = $2; ver = $3
            if (name in repo) {
                src = repo[name]
                kind = (src ~ /^(deb|security)\.debian\.org/) ? "repo" : "third-party"
            } else {
                src = "local"; kind = "manual"
            }
            printf "%s\t%s\t%s\t%s\t%s\n", name, ver, src, kind, (name in manual ? "y" : "n")
        }
    ' | sort

    rm -f "$_tmp" "$_tmp.manual"
}
#!/bin/bash

antivirus_update()
{
    freshclam
}

antivirus_scan()
{
    clamscan -r --bell -i "$@"
}

aur_scan()
{
    local pkgdir="${1:-$PWD}"
    local pkgbuild="$pkgdir/PKGBUILD"

    if [[ ! -f "$pkgbuild" ]]; then
        printf 'Error: no PKGBUILD in %s\n' "$pkgdir" >&2
        return 2
    fi

    if [[ -d "$pkgdir/.git" ]]; then
        printf '\n=== git log (5) ===\n'
        git -C "$pkgdir" --no-pager log -5 --format='%h %ci %an <%ae> %s'
        printf '\n=== git diff (last update HEAD~5..HEAD) ===\n'
        git -C "$pkgdir" --no-pager diff HEAD~5 HEAD 2>/dev/null \
            || printf '(single commit, nothing to diff)\n'
    fi

    printf '\n=== PKGBUILD ===\n'
    cat "$pkgbuild"

    local f
    for f in "$pkgdir"/*.install; do
        [[ -f "$f" ]] || continue
        printf '\n=== %s ===\n' "$(basename "$f")"
        cat "$f"
    done

    # Tier 1: known malicious payload names -> hard block. Reliable but past-only.
    printf '\n=== IOC scan (known payloads) ===\n'
    if grep -rn -E 'atomic-lockfile|js-digest|lockfile-js' "$pkgdir" >&2; then
        printf 'DANGER: known malicious payload found.\n' >&2
        return 1
    fi

    # Tier 2: heuristic warnings only. A blacklist always loses to obfuscation
    # (string splitting / mixed quoting defeat regex) -> review-aid, never a gate.
    printf '\n=== heuristic scan (review-aid, not exhaustive) ===\n'
    local found=0
    # package managers fetching/executing code (covers obfuscated npm/pip/etc + lifecycle hooks)
    grep -rn -E '(npm|pnpm|yarn|bun|pip|pipx|gem|composer|cargo|go)[[:space:]]+(install|add|exec|run|i)\b|preinstall|postinstall' \
        --include='PKGBUILD' --include='*.install' "$pkgdir" && found=1
    # network fetch piped to interpreter
    grep -rn -E '(curl|wget|fetch)[^|]*\|[^|]*(sh|bash|zsh|python|perl|node|ruby)' \
        --include='PKGBUILD' --include='*.install' "$pkgdir" && found=1
    # decode/eval + hex escapes (catches \xHH obfuscation seen in Atomic Arch)
    grep -rn -E 'base64[[:space:]]+(-d|--decode)|\beval[[:space:]]|\\x[0-9a-fA-F]{2}' \
        --include='PKGBUILD' --include='*.install' "$pkgdir" && found=1
    # persistence: cron / systemd / shell-rc append / autostart / eBPF
    grep -rn -E 'crontab|systemctl|/etc/cron|autostart|/sys/fs/bpf|nohup|>>[[:space:]]*[^;&]*\.(bashrc|bash_profile|profile|zshrc)' \
        --include='PKGBUILD' --include='*.install' "$pkgdir" && found=1

    if [[ "$found" -eq 1 ]]; then
        printf 'WARNING: patterns above need review. Note: obfuscation can hide more.\n' >&2
    else
        printf 'No known-bad patterns. Still read the PKGBUILD/diff above.\n'
    fi

    return 0
}

aur_install()
{
    local pkgdir="${1:-$PWD}"

    aur_scan "$pkgdir" || { printf 'Aborted: scan failed.\n' >&2; return 1; }

    ask_confirm "Proceed with build?" || { printf 'Aborted.\n' >&2; return 1; }

    ( cd "$pkgdir" && makepkg --syncdeps --install --clean )
}

wireguard_add()
{
    mcli connection import type wireguard file "$1"
}

pacman_update()
{
    sudo /usr/bin/pacman -Syu
}

pacman_install()
{
    sudo /usr/bin/pacman -S --noconfirm "$@"
}

pacman_remove()
{
    sudo /usr/bin/pacman -R --noconfirm "$@"
}

pacman_search()
{
    pacman -Ss "$@"
}

pacman_info()
{
    pacman -Qi "$@"
}

pacman_list()
{
    pacman -Q "$@"
}

pacman_list_orphans()
{
    pacman -Qdtq
}

pacman_list_installed()
{
    pacman -Qe
}

pacman_list_all()
{
    pacman -Q
}
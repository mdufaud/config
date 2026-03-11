#!/bin/bash
# Bash completion for make - completes targets from Makefile
_make_completion() {
    local cur targets

    cur="${COMP_WORDS[COMP_CWORD]}"

    # Only complete the first argument (the target)
    [[ "${COMP_WORDS[COMP_CWORD-1]}" == -* ]] && return 0

    # Requires a Makefile in the current directory
    [[ -f GNUmakefile || -f makefile || -f Makefile ]] || return 0

    # Extract real targets: make -qp resolves all includes
    # Filter out: pattern rules, file paths, internal make vars
    targets=$(make -qp 2>/dev/null \
        | awk -F: '/^[a-zA-Z0-9][a-zA-Z0-9_\-]*[[:space:]]*:([^=]|$)/{
            gsub(/[[:space:]].*/, "", $1); print $1
        }' \
        | sort -u)

    COMPREPLY=( $(compgen -W "${targets}" -- "${cur}") )
    return 0
}
complete -F _make_completion make

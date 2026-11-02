#!/usr/bin/env bash
set -euo pipefail

mapfile -t unmerged < <(git diff --name-only --diff-filter=U)
if ((${#unmerged[@]})); then
  printf 'Unresolved conflicts:\n'
  printf '  %s\n' "${unmerged[@]}"
  exit 1
fi

target=${1:-}
if [[ -z $target ]]; then
  main=$(git branch-main)
  git fetch -q origin "$main"
  target="origin/$main"
fi

rc=0
out=$(git merge-tree --write-tree --name-only --no-messages HEAD "$target") || rc=$?

case $rc in
  0) printf 'No conflicts merging %s into HEAD\n' "$target" ;;
  1)
    printf 'Conflicts merging %s into HEAD:\n' "$target"
    tail -n +2 <<<"$out" | sed '/^$/d' | sort -u | sed 's/^/  /'
    exit 1
    ;;
  *) exit "$rc" ;;
esac

#!/usr/bin/env bash
set -euo pipefail

if ref=$(git symbolic-ref --short -q refs/remotes/origin/HEAD 2>/dev/null); then
  printf '%s\n' "${ref#origin/}"
  exit 0
fi

for name in main master; do
  if git show-ref --verify --quiet "refs/heads/$name" || git show-ref --verify --quiet "refs/remotes/origin/$name"; then
    printf '%s\n' "$name"
    exit 0
  fi
done

printf 'Error: cannot determine main branch (try: git remote set-head origin -a)\n' >&2
exit 1

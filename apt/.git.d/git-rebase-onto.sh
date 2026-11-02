#!/usr/bin/env bash
set -euo pipefail

old=${1:-}
[[ -n $old ]] || { printf 'Usage: git rebase-onto <old-base> [<new-base>]\n' >&2; exit 2; }
git rev-parse -q --verify "$old^{commit}" >/dev/null || { printf 'Error: unknown commit: %s (try git reflog)\n' "$old" >&2; exit 1; }

new=${2:-}
if [[ -z $new ]]; then
  main=$(git branch-main)
  git fetch origin "$main"
  new="origin/$main"
fi

count=$(git rev-list --count "$old..HEAD")
((count)) || { printf 'Error: no commits between %s and HEAD\n' "$old" >&2; exit 1; }

printf 'Replaying %s commit(s) onto %s:\n' "$count" "$new"
git log --oneline "$old..HEAD"
exec git rebase --autostash --onto "$new" "$old"

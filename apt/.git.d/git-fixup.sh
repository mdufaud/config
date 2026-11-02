#!/usr/bin/env bash
set -euo pipefail

die() {
  printf 'Error: %s\n' "$1" >&2
  exit 1
}

git rev-parse --git-dir >/dev/null
git diff --cached --quiet && die 'nothing staged (git add the fix first)'

main=$(git branch-main)
base="origin/$main"
git rev-parse -q --verify "$base" >/dev/null || base="$main"
[[ -n $(git rev-list "$base..HEAD") ]] || die "no commits ahead of $base"

target=${1:-}
if [[ -z $target ]]; then
  command -v fzf >/dev/null || die 'fzf is required (or pass a commit)'
  line=$(git log --color=always --format='%C(auto)%h %s %C(bold black)%cr' "$base..HEAD" |
    fzf --ansi --no-sort --reverse --header 'Commit to fix' --preview 'git show --color=always --stat {1}') || exit 1
  target=${line%% *}
fi

git rev-parse -q --verify "$target^{commit}" >/dev/null || die "unknown commit: $target"
git merge-base --is-ancestor "$target" HEAD || die "$target is not in the current branch"
git merge-base --is-ancestor "$target" "$base" && die "$target is already in $base"

pushed=false
upstream=$(git rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>/dev/null || true)
if [[ -n $upstream ]] && git merge-base --is-ancestor "$target" "$upstream"; then
  pushed=true
fi

git commit -q --fixup="$target"
GIT_SEQUENCE_EDITOR=true git rebase -i --autosquash --autostash "$target^" || die 'rebase stopped, fix it then: git rbc (or git rba to abort)'

$pushed && printf 'Pushed commit rewritten, update the remote with: git sync (or git pushfwl)\n'
exit 0

#!/usr/bin/env bash
set -euo pipefail

main=$(git branch-main)
base="origin/$main"
git rev-parse -q --verify "$base" >/dev/null || base="$main"

declare -A merged=()
while IFS= read -r name; do
  merged["$name"]=1
done < <(git branch --merged "$base" --format '%(refname:short)')

sep=$'\x1f'
format="%(refname:short)%1f%(HEAD)%1f%(committerdate:relative)%1f%(upstream)%1f%(upstream:track,nobracket)%1f%(ahead-behind:$base)%1f%(worktreepath)"

{
  printf 'BRANCH\tAGE\tAHEAD/BEHIND\tUPSTREAM\tFLAGS\n'
  while IFS="$sep" read -r name head age upstream track counts wt; do
    state=ok
    if [[ -z $upstream ]]; then
      state=none
    elif [[ -n $track ]]; then
      state=$track
    fi

    read -r ahead behind <<<"$counts"

    flags=()
    [[ $head == '*' ]] && flags+=(current)
    [[ -n ${merged[$name]:-} && $name != "$main" ]] && flags+=(merged)
    [[ -n $wt && $head != '*' ]] && flags+=(worktree)

    printf '%s\t%s\t+%s/-%s\t%s\t%s\n' "$name" "$age" "$ahead" "$behind" "$state" "$(IFS=,; printf '%s' "${flags[*]:--}")"
  done < <(git for-each-ref --sort=committerdate refs/heads --format="$format")
} | column -ts $'\t'

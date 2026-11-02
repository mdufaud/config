#!/usr/bin/env bash
set -euo pipefail

remote=false
dry_run=false
yes=false
all_authors=false

usage() {
  printf 'Usage: git branch-prune [-n|--dry-run] [-y|--yes]\n'
  printf '       git branch-prune-remote [-n|--dry-run] [-y|--yes] [-a|--all-authors]\n'
}

while (($#)); do
  case $1 in
    -r|--remote) remote=true ;;
    -n|--dry-run) dry_run=true ;;
    -y|--yes) yes=true ;;
    -a|--all-authors) all_authors=true ;;
    -h|--help) usage; exit 0 ;;
    *) usage >&2; exit 2 ;;
  esac
  shift
done

main=$(git branch-main)
git fetch --prune origin || printf 'Warning: fetch failed, remote state may be stale\n' >&2

base="origin/$main"
if ! git rev-parse -q --verify "$base" >/dev/null; then
  $remote && { printf 'Error: %s not found\n' "$base" >&2; exit 1; }
  base="$main"
fi

protected=" main master develop trunk $main "
sep=$'\x1f'
candidates=()

if $remote; then
  me=$(git config user.email)
  while IFS="$sep" read -r name sha age author email; do
    [[ $name == HEAD || $name == release/* || $protected == *" $name "* ]] && continue
    $all_authors || [[ $email == "$me" ]] || continue
    candidates+=("$(printf '%s\tmerged\t%s\t%s\t%s' "$name" "$sha" "$age" "$author")")
  done < <(git for-each-ref refs/remotes/origin --merged "$base" --format='%(refname:lstrip=3)%1f%(objectname:short)%1f%(committerdate:relative)%1f%(authorname)%1f%(authoremail:trim)')
else
  current=$(git branch --show-current)

  declare -A merged=()
  while IFS= read -r name; do
    merged["$name"]=1
  done < <(git branch --merged "$base" --format '%(refname:short)')

  while IFS="$sep" read -r name track wt sha age author; do
    [[ $protected == *" $name "* || $name == "$current" || -n $wt ]] && continue
    reasons=()
    [[ $track == gone ]] && reasons+=(gone)
    [[ -n ${merged[$name]:-} ]] && reasons+=(merged)
    ((${#reasons[@]})) || continue
    candidates+=("$(printf '%s\t%s\t%s\t%s\t%s' "$name" "$(IFS=,; printf '%s' "${reasons[*]}")" "$sha" "$age" "$author")")
  done < <(git for-each-ref refs/heads --format='%(refname:short)%1f%(upstream:track,nobracket)%1f%(worktreepath)%1f%(objectname:short)%1f%(committerdate:relative)%1f%(authorname)')
fi

if ((${#candidates[@]} == 0)); then
  printf 'Nothing to prune.\n'
  exit 0
fi

print_table() {
  printf '%s\n' "${candidates[@]}" | column -ts $'\t'
}

selected=()
if $dry_run; then
  print_table
  exit 0
elif $yes; then
  selected=("${candidates[@]}")
elif [[ -t 0 && -t 1 ]] && command -v fzf >/dev/null; then
  prefix=
  $remote && prefix=origin/
  mapfile -t selected < <(printf '%s\n' "${candidates[@]}" | fzf --multi --bind 'start:select-all' --delimiter $'\t' \
    --header 'TAB toggle, ENTER delete selected, ESC cancel' \
    --preview "git log --oneline --color=always -15 ${prefix}{1} --" || true)
else
  print_table
  printf 'Re-run with --yes to delete all of the above.\n'
  exit 0
fi

if ((${#selected[@]} == 0)); then
  printf 'Nothing selected.\n'
  exit 0
fi

names=()
for line in "${selected[@]}"; do
  IFS=$'\t' read -r name _ sha _ <<<"$line"
  names+=("$name")
  printf '%s %s\n' "$name" "$sha"
done

if $remote; then
  printf 'Restore with: git push origin <sha>:refs/heads/<name>\n'
  git push origin --delete "${names[@]}"
else
  for name in "${names[@]}"; do
    git branch -D "$name"
  done
fi

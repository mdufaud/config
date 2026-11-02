#!/usr/bin/env bash
set -euo pipefail

push=true
case ${1:-} in
  -n|--no-push) push=false ;;
  '') ;;
  *) printf 'Usage: git sync [-n|--no-push]\n' >&2; exit 2 ;;
esac

die() {
  printf 'Error: %s\n' "$1" >&2
  exit 1
}

git_dir=$(git rev-parse --git-dir)
[[ -d $git_dir/rebase-merge || -d $git_dir/rebase-apply ]] && die 'rebase in progress'

branch=$(git branch --show-current)
[[ -n $branch ]] || die 'detached HEAD'

main=$(git branch-main)
protected=" main master develop trunk $main "

git fetch --prune origin

upstream=$(git rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>/dev/null || true)

if [[ $protected == *" $branch "* ]]; then
  [[ -n $upstream ]] || die "no upstream for $branch"
  git merge --autostash --ff-only "$upstream"
  exit 0
fi

if git rev-parse -q --verify "refs/heads/$main" >/dev/null; then
  git fetch origin "$main:$main" 2>/dev/null || printf 'Warning: local %s not fast-forwarded, left as is\n' "$main" >&2
fi

if [[ -n $upstream && -n $(git rev-list "HEAD..$upstream") ]]; then
  die "$upstream has commits not in $branch, run 'git pull' first"
fi

git rebase --autostash "origin/$main" || die 'rebase stopped, fix it then: git rebase --continue (nothing pushed)'

$push || { printf 'Rebased on origin/%s, push skipped\n' "$main"; exit 0; }

if [[ -z $upstream ]]; then
  printf 'Rebased on origin/%s, no upstream so nothing pushed (git push-first to publish)\n' "$main"
  exit 0
fi

if [[ $(git rev-parse HEAD) == "$(git rev-parse "$upstream")" ]]; then
  printf 'Rebased on origin/%s, upstream already up to date\n' "$main"
  exit 0
fi

remote=$(git config "branch.$branch.remote")
ref=$(git config "branch.$branch.merge")

if git merge-base --is-ancestor "$upstream" HEAD; then
  git push "$remote" "HEAD:$ref"
else
  git push --force-with-lease --force-if-includes "$remote" "HEAD:$ref"
fi

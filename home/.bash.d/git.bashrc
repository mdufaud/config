#!/bin/bash
#
# Git
#

if bin_exists git; then
  # check if include path has ~/.gitalias - if not add it
  if ! git config --get-all include.path | grep '~/.gitalias' 1>/dev/null 2>/dev/null; then
    git config --global --add include.path '~/.gitalias'
  fi
fi

# alias gita="git add -A"
# alias gitc="git commit -m"
# alias gits="git status"
function git_rebase_from_head()
{
  _arg_assert_number "${1:-}" "usage: git_rebase_from_head <count>" || return
  git rebase -i "HEAD~$1"
}
# alias git_rebase_abort="git rebase --abort"
# alias git_rebase_continue="git rebase --continue"
alias git_amend="git commit --amend"
alias git_conf="git config --list --show-origin --show-scope"
alias is_git_repo="git rev-parse --is-inside-work-tree 2>&- 1>&-"

function git_select()
(
  local __git_log_output
  if __git_log_output=$(git log --color=always --format='%C(auto)%H%d %s %C(black)%C(bold)%cr %Cblue[%cn]%Creset'); then
    gum filter --placeholder 'Filter...' --indicator=">" < <(echo "$__git_log_output") | sed 's/\x1b\[[0-9;]*m//g' | cut -d' ' -f1 | clip_copy
  fi
)
alias gitsel="git_select"

function git_diff()
{
  bash "$HOME/.git.d/git-interactive-diff.sh" --graph "$@"
}
alias gitdiff="git_diff"

function git_discard()
{
  ask_confirm 'Are you sure you want to delete your last commit and all your changes ?' \
    && git reset --hard HEAD~1 \
    || echo "aborted"
}

function git_debug()
{
  export GIT_TRACE_PACKET=1
  export GIT_TRACE=1
  export GIT_CURL_VERBOSE=1
}

function git_undebug()
{
  export GIT_TRACE_PACKET=
  export GIT_TRACE=
  export GIT_CURL_VERBOSE=
}

function git_diff_apply()
{
  opt_begin "git_diff_apply <src_repo> <dst_repo>"
  opt_desc  "Apply src repo's diff onto dst repo's working tree"
  opt_flag  s staged  "Diff staged changes (--cached) instead of working tree"
  opt_parse "$@" || return

  local src="${opt_args[0]}"
  local dst="${opt_args[1]}"
  _arg_assert_exists "$src" "$opt_usage" || return
  _arg_assert_exists "$dst" "$opt_usage" || return

  [ -d "$src/.git" ] || { print_err "not a git repo: $src"; return 1; }
  [ -d "$dst/.git" ] || { print_err "not a git repo: $dst"; return 1; }

  local diff_flag=""
  [ "$opt_staged" = true ] && diff_flag="--cached"

  (cd "$src" && git diff $diff_flag) | (cd "$dst" && git apply --check -) \
    && (cd "$src" && git diff $diff_flag) | (cd "$dst" && git apply) \
    || { print_err "apply failed (patch didn't check out clean)"; return 1; }
}

# git_actions_why [workflow | run_id]
#   Print why a GitHub Actions run failed: failed jobs, faulty step, deduped errors.
#   Without argument: pick the run with fzf. A numeric argument is a run id,
#   anything else filters the fzf list by workflow name.
function git_actions_why()
{
  local run_id=""
  local workflow=""
  local arg="${1:-}"

  bin_exists gh || { print_err "gh is required"; return 1; }

  if arg_exists "$arg"; then
    if arg_is_number "$arg"; then
      run_id="$arg"
    else
      workflow="$arg"
    fi
  fi

  if ! arg_exists "$run_id"; then
    bin_exists fzf || { print_err "fzf is required (or pass a run id)"; return 1; }

    local runs sel
    runs="$(gh run list --limit 30 ${workflow:+--workflow="$workflow"} \
      --json databaseId,workflowName,status,conclusion,headBranch,event,createdAt,displayTitle \
      --jq '.[] | [.databaseId, .workflowName, (if .conclusion then .conclusion else .status end), .headBranch, .event, (.createdAt[0:16] | sub("T"; " ")), .displayTitle] | @tsv')" || {
      print_err "no run found${workflow:+ for '$workflow'} (not in a github repo ?)"
      return 1
    }
    arg_exists "$runs" || { print_err "no run found${workflow:+ for '$workflow'}"; return 1; }

    sel="$(printf '%s\n' "$runs" | fzf --delimiter='\t' --with-nth=2,3,4,6,7 \
      --preview='gh run view {1}' --preview-window=right:60%:wrap \
      --header='run · workflow · state · branch · event · date · title')" || return 0
    run_id="${sel%%$'\t'*}"
  fi

  local info
  info="$(gh run view "$run_id" --json databaseId,workflowName,conclusion,status,createdAt,updatedAt,event,headBranch,url,jobs)" || {
    print_err "run '$run_id' not found"
    return 1
  }

  local state failed_count
  state="$(echo "$info" | jq -r '.conclusion // .status')"
  failed_count="$(echo "$info" | jq '[.jobs[]? | select(.conclusion == "failure")] | length')"

  if [ "$failed_count" = "0" ]; then
    if [ "$state" = "success" ]; then
      echo "$info" | jq -r '"\(."workflowName") #\(."databaseId") is green ✓"'
    else
      echo "$info" | jq -r '"\(."workflowName") #\(."databaseId") \(."conclusion" // .status) with no job started — check the workflow file"'
      echo "url: $(echo "$info" | jq -r '.url')"
    fi
    return 0
  fi

  echo "$info" | jq -r '
    ((."updatedAt" | fromdateiso8601) - (."createdAt" | fromdateiso8601)) as $s
    | "\(."workflowName") #\(."databaseId") \(.conclusion // .status) · \(.headBranch) · \(.event) · \( ($s / 60 | floor) )m\( $s % 60 )s · \(.createdAt)",
    ([.jobs[] | select(.conclusion == "failure")][]
      | "✗ \(.name[0:60])",
        "    step: \([.steps[] | select(.conclusion == "failure") | .name] | join(", "))"),
    ""
  '

  local errors
  errors="$(gh run view "$run_id" --log-failed \
    | cut -f3- \
    | sed -E 's/^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9:.]+Z[[:space:]]+//; s/^\[[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9:.]+\][[:space:]]*//' \
    | grep -aE '##\[error\]|builder \[(error|fatal)\]|[Ee]rror:|FAILED:|fatal error:|undefined (reference|symbol)|scons: \*\*\*|ninja: build stopped' \
    | sed -E 's/^##\[error\][[:space:]]*//; /^Process completed with exit code/d' \
    | awk '!seen[$0]++' || true)"

  if arg_exists "$errors"; then
    echo "errors (deduped):"
    echo "$errors" | sed 's/^/  /'
  else
    echo "no error line matched — see the full failed log:"
    echo "  gh run view $run_id --log-failed"
  fi
  echo ""
  echo "url: $(echo "$info" | jq -r '.url')"
}
alias gitawhy="git_actions_why"
alias gitnwhy="git_actions_why ci-nightly"

function git_fix_remote()
{
  local remote="${1:-origin}"

  git rev-parse --show-toplevel &>/dev/null || {
    print_err "not inside a Git repository"
    return 1
  }

  local https_url
  https_url="$(git remote get-url "$remote" 2>/dev/null)" || {
    print_err "remote '$remote' not found"
    return 1
  }

  echo "Remote '$remote' current URL: $https_url"

  if [[ "$https_url" != https://* ]]; then
    echo "Remote is already SSH (or not HTTPS). Nothing to convert."
  else
    local ssh_url
    ssh_url="$(echo "$https_url" | sed -E 's|^https://([^/]+)/(.+)|git@\1:\2|')"

    if [[ "$ssh_url" != *.git ]]; then
      ssh_url="${ssh_url}.git"
    fi

    echo "Converting to SSH: $ssh_url"
    git remote set-url "$remote" "$ssh_url"
    echo "Remote URL updated."
  fi

  echo ""
  echo "Checking push access…"
  if git push --dry-run "$remote" HEAD 2>&1; then
    echo "✓ Push access OK."
  else
    print_err "Push failed — check your SSH key and remote permissions."
    return 2
  fi
}

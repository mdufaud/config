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
alias git_rebase_from_head="git rebase -i HEAD~"
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
  git log --graph --color=always --format='%C(auto)%h%d %s %C(black)%C(bold)%cr %Cblue[%cn]%Creset' "$@" |
  fzf --ansi --no-sort --reverse --tiebreak=index --bind=ctrl-s:toggle-sort \
      --preview "(echo {} | grep -o '[a-f0-9]\{7,\}' | head -1 | xargs -I % sh -c 'git show --color=always %')" \
      --bind "ctrl-m:execute: (grep -o '[a-f0-9]\{7,\}' | head -1 | xargs -I % sh -c 'git show --color=always % | less -R') << 'FZF-EOF'
                {}
FZF-EOF"
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

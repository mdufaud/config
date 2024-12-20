#!/bin/bash

__fzf_git="$HOME/apt/fzf-git/fzf-git.sh"

source "$__fzf_git"

_fzf_git_fzf() {
  fzf --height=50% --tmux 90%,70% \
    --layout=reverse --multi --min-height=20 --border \
    --border-label-pos=2 \
    --color='header:italic:underline,label:blue' \
    --preview-window='right,50%,border-left' \
    --bind='ctrl-/:change-preview-window(down,50%,border-top|hidden|)' "$@"
}

_fzf_git_check() {
  git rev-parse HEAD > /dev/null 2>&1 && return

  [[ -n $TMUX ]] && tmux display-message "Not in a git repository"
  return 1
}

_fzf_git_check || exit 1
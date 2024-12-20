#!/bin/bash

source "$HOME/.git.d/git-interactive-init.sh"

bash "$__fzf_git" --list hashes |
_fzf_git_fzf --ansi --no-sort \
  --border-label '🍡 Hashes' \
  --header-lines 3 \
  --tiebreak begin \
  --preview-window down,border-top,40% \
  --color hl:underline,hl+:underline \
  --bind 'ctrl-s:toggle-sort' \
  --bind "ctrl-o:execute-silent:bash \"$__fzf_git\" --list commit {}" \
  --bind "ctrl-d:execute:grep -o '[a-f0-9]\{7,\}' <<< {} | head -n 1 | xargs git diff --color=$(__fzf_git_color) > /dev/tty" \
  --bind "alt-a:change-border-label(🍇 All hashes)+reload:bash \"$__fzf_git\" --list all-hashes" \
  --preview "grep -o '[a-f0-9]\{7,\}' <<< {} | head -n 1 | xargs git show --color=$(__fzf_git_color .) | $(__fzf_git_pager)" "$@" |
awk 'match($0, /[a-f0-9][a-f0-9][a-f0-9][a-f0-9][a-f0-9][a-f0-9][a-f0-9][a-f0-9]*/) { print substr($0, RSTART, RLENGTH) }'

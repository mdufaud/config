#!/bin/bash

source "$HOME/.git.d/git-interactive-init.sh"

git tag --sort -version:refname |
_fzf_git_fzf --preview-window right,70% \
  --border-label '📛 Tags' \
  --header $'CTRL-O (open in browser)\n\n' \
  --bind "ctrl-o:execute-silent:bash \"$__fzf_git\" --list tag {}" \
  --preview "git show --color=$(__fzf_git_color .) $(echo {} | cut -d' ' -f1) | $(__fzf_git_pager)" "$@"
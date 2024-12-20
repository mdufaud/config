#!/bin/bash

_git_check() {
  git rev-parse HEAD > /dev/null 2>&1 && return
}
_git_check || exit 1

git log --color=always --format='%C(auto)%h%d %s %C(black)%C(bold)%cr %Cblue[%cn]%Creset' "$@" |
fzf --ansi --no-sort --reverse --tiebreak=index --bind=ctrl-s:toggle-sort \
    --preview "(echo {} | grep -o '[a-f0-9]\{7\}' | head -1 | xargs -I % sh -c 'git show --color=always %')" \
    --bind "ctrl-m:execute: (grep -o '[a-f0-9]\{7\}' | head -1 | xargs -I % sh -c 'git show --color=always % | less -R') << 'FZF-EOF'
              {}
FZF-EOF"
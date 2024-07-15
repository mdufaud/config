#!/bin/bash

#
# Git
#

alias gita="git add -A"
alias gitc="git commit -m"
alias gits="git status"
alias git_rebase_from_head="git rebase -i HEAD~"
alias git_rebase_abort="git rebase --abort"
alias git_rebase_continue="git rebase --continue"
alias git_amend="git commit --amend"

alias is_git_repo="git rev-parse --is-inside-work-tree 2>&- 1>&-"

function git_select()
(
    local __git_log_output
    if __git_log_output=$(git log --oneline --graph --color=always --format='%C(auto)%h%d %s %C(black)%C(bold)%cr %Cblue[%cn]%Creset'); then
        gum filter --placeholder 'Filter...' --indicator=">" < <(echo "$__git_log_output") | cut -d' ' -f1 # | copy
    fi
)
alias gitsel="git_select"

function git_diff()
{
  git log --graph --color=always \
      --format='%C(auto)%h%d %s %C(black)%C(bold)%cr %Cblue[%cn]%Creset' "$@" |
  fzf --ansi --no-sort --reverse --tiebreak=index --bind=ctrl-s:toggle-sort \
      --bind "ctrl-m:execute:
                (grep -o '[a-f0-9]\{7\}' | head -1 |
                xargs -I % sh -c 'git show --color=always % | less -R') << 'FZF-EOF'
                {}
FZF-EOF"
}
alias gitdiff="git_diff"

#
# VCPKG
#

vcpkg_baseline()
(
    _arg_assert_exists "$1" "vcpkg_baseline <libname>" || return

    local __commit=${2:-HEAD}

    if dir_exists ".vcpkg"; then
        cd .vcpkg
    fi

    if ! file_exists "bootstrap-vcpkg.sh"; then
        return 1
    fi

    git show $__commit:versions/baseline.json | egrep -A 3 -e "$1"
)

#
# Python venv
#

alias venv="source .venv/bin/activate"

#
# RabbitMQ
#

rmq_list()
{
  _arg_assert_binary rabbitmqctl "No rabbitmqctl found" || return

  local __res=$(sudo rabbitmqctl list_queues)

  # keep first 3 lines
  echo "$__res" | head -n 3
  # delete first 3 lines and sort rest
  echo "$__res" | sed -e "1,3d" | sort
}

rmq_purge()
{
  _arg_assert_binary rabbitmqctl "No rabbitmqctl found" || return

  if [ $# -eq 0 ]
  then
    ask_confirm "Are you sure you want to purge all rabbitMQ ?" || return
    sudo rabbitmqctl list_queues | tail -n +4 | awk '{print $1}' | xargs -I {} sudo rabbitmqctl purge_queue {}
  else
    local __var
    for __var in "$@"
    do
      echo "Purging queue $__var"
      sudo rabbitmqctl purge_queue $__var
    done
  fi
}

rmq_delete()
{
  _arg_assert_binary rabbitmqctl "No rabbitmqctl found" || return

  if [ $# -eq 0 ]
  then
    ask_confirm "Are you sure you want to delete all rabbitMQ ?" || return
    sudo rabbitmqctl list_queues | tail -n +4 | awk '{print $1}' | xargs -I {} sudo rabbitmqctl delete_queue {}
  else
    local __var
    for __var in "$@"
    do
      echo "Deleting queue $__var"
      sudo rabbitmqctl delete_queue $__var
    done
  fi
}

#
# Emscripten
#

export EMSDK_QUIET=1
if [ -r "~/emscripten/emsdk/emsdk_env.sh" ]; then
  source ~/emscripten/emsdk/emsdk_env.sh
fi

#
# Bat
#

_install_bat()
{
    sudo apt install bat
    ln -s /usr/bin/batcat ~/.local/bin/bat
}

batfollow()
{
    tail -f "$1" | bat --paging=never -l log
}

if bin_exists bat; then
    export MANPAGER="sh -c 'col -b | bat -l man -p'"
fi

#
# Fzf
#

_install_fzf()
{
    local fzf_path="$HOME/apt/fzf"

    mkdir -p $(dirname $fzf_path)

    if [ -e $fzf_path ]; then
        git -C $fzf_path pull
    else
        git clone --depth 1 https://github.com/junegunn/fzf.git $fzf_path
    fi

    $fzf_path/install

    eval "$(fzf --bash)"
}

if [[ ! "$PATH" == *$HOME/apt/fzf/bin* ]]; then
    PATH="${PATH}:$HOME/apt/fzf/bin"
fi

if bin_exists fzf; then
    eval "$(fzf --bash)"
fi

#
# Neovim
#

_install_nvim()
{
    local _nvim_ver=${1:-v0.10.0}

    echo "Installing neovim version $_nvim_ver"

    curl https://github.com/neovim/neovim/releases/download/$_nvim_ver/nvim.appimage --output $HOME/.local/bin
    chmod +x $HOME/.local/bin/nvim.appimage
    mv $HOME/.local/bin/nvim.appimage $HOME/.local/bin/nvim

    mkdir -p $HOME/.config/nvim
    curl https://raw.githubusercontent.com/nvim-lua/kickstart.nvim/master/init.lua --output $HOME/.config/nvim/init.lua

    echo "Use :Mason to install code servers"
}

#
# Rg
#

_install_rg()
{
    if bin_exists apt; then
        (
            cd /tmp && \
            curl -LO https://github.com/BurntSushi/ripgrep/releases/download/14.1.0/ripgrep_14.1.0-1_amd64.deb && \
            sudo dpkg -i /tmp/ripgrep_14.1.0-1_amd64.deb
        )
    elif bin_exists pacman; then
        sudo pacman -S ripgrep
    fi
}

if bin_exists rg; then
    export FZF_DEFAULT_COMMAND="rg --files --hidden -g '!.git'"
    export FZF_CTRL_T_COMMAND="rg --files --hidden -g '!.git'"
fi
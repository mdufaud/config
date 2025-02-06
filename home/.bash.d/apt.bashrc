export APT_DIR="$HOME/apt"

function install_list()
(
  set -e

  if ! bin_exists fzf; then
    _install_fzf
  fi

  local list="$(declare -F | grep _install_ | sed 's/declare -f //g')"
  local selection="$(echo "$list" | fzf --multi --cycle)"

  for cmd in ${selection}; do
    echo "$cmd"
    $cmd
  done
)

__prepare_local_install()
{
  mkdir -p "$APT_DIR/bin"
  mkdir -p "$HOME/.local/bin"
}

__pkg_manager_install()
{
  local opt_sudo
  if bin_exists sudo; then opt_sudo="sudo"; fi

  if bin_exists pacman; then
    $opt_sudo pacman -S $@
  elif bin_exists pkg; then
    $opt_sudo pkg install $@
  elif bin_exists apt; then
    $opt_sudo apt install $@
  elif bin_exists apk; then
    $opt_sudo apk add $@
  elif bin_exists dnf; then
    $opt_sudo dnf install $@
  elif bin_exists brew; then
    $opt_sudo brew install $@
  fi
}

#
# Git
#

if bin_exists git; then
  # check if include path has ~/.gitalias - if not add it
  if ! git config --get-all include.path | grep '~/.gitalias' 1>/dev/null 2>/dev/null; then
    git config --global --add include.path '~/.gitalias'
  fi
fi

alias gita="git add -A"
alias gitc="git commit -m"
alias gits="git status"
alias git_rebase_from_head="git rebase -i HEAD~"
alias git_rebase_abort="git rebase --abort"
alias git_rebase_continue="git rebase --continue"
alias git_amend="git commit --amend"
alias git_conf="git config --list --show-origin --show-scope"
alias is_git_repo="git rev-parse --is-inside-work-tree 2>&- 1>&-"

function git_select()
(
  local __git_log_output
  if __git_log_output=$(git log --oneline --color=always --format='%C(auto)%H%d %s %C(black)%C(bold)%cr %Cblue[%cn]%Creset'); then
    gum filter --placeholder 'Filter...' --indicator=">" < <(echo "$__git_log_output") | cut -d' ' -f1  | clip_copy
  fi
)
alias gitsel="git_select"

function git_diff()
{
  git log --graph --color=always --format='%C(auto)%h%d %s %C(black)%C(bold)%cr %Cblue[%cn]%Creset' "$@" |
  fzf --ansi --no-sort --reverse --tiebreak=index --bind=ctrl-s:toggle-sort \
      --preview "(echo {} | grep -o '[a-f0-9]\{7\}' | head -1 | xargs -I % sh -c 'git show --color=always %')" \
      --bind "ctrl-m:execute: (grep -o '[a-f0-9]\{7\}' | head -1 | xargs -I % sh -c 'git show --color=always % | less -R') << 'FZF-EOF'
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

venv()
{
  local venv_path=".venv"
  local venv_activate="$venv_path/bin/activate"

  if [[ ! -f $venv_activate ]]; then
    python -m venv $venv_path
  fi

  source $venv_activate
}

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
# Bat (cli better cat)
#

_install_bat()
(
  set -e

  if ! bin_exists batcat; then
    __pkg_manager_install bat
  fi

  __prepare_local_install

  if bin_exists batcat; then
    rm -f $HOME/.local/bin/bat
    ln -s $(command -v batcat) $HOME/.local/bin/bat
  fi
)

bat_follow()
{
  tail -f "$1" | bat --paging=never -l log
}
alias batf="bat_follow"

if bin_exists bat; then
  export MANPAGER="sh -c 'col -b | bat -l man -p'"
fi

#
# Valgrind
#

alias valgrind_leak="valgrind --leak-check=yes"
alias vleak="valgrind_leak"

cachegrind() (
  valgrind --tool=cachegrind $1 &
  local pid=$!
  trap "kill -SIGINT $pid" INT
  wait

  sleep 0.5
  local cachegrind_file_path="cachegrind.out.$pid"
  cg_annotate $cachegrind_file_path

  if [ -f $cachegrind_file_path ] && ask_confirm "Delete cachegrind file ?"; then
    rm $cachegrind_file_path
  fi
)

callgrind() (
  valgrind --tool=callgrind $1 &
  local pid=$!
  trap "kill -SIGINT $pid" INT
  wait

  sleep 0.5
  local callgrind_file_path="callgrind.out.$pid"
  callgrind_annotate --threshold=98 --context=3 $callgrind_file_path

  if [ -f $callgrind_file_path ] && ask_confirm "Delete callgrind file ?"; then
    rm $callgrind_file_path
  fi
)

#
# Zoxide (cd database)
#

_install_zoxide()
{
  curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh
  eval "$(zoxide init bash)"
  alias cd="z"
}

if bin_exists zi; then
  alias cd="z"
  eval "$(zoxide init bash)"
fi

#
# Fzf (cli fuzzy finder)
#

fzf_select()
{
  local args="$1"
  shift
  if [ -z "$args" ]; then
    return 0
  fi

  local words=( $args )
  local nb_words=${#words[@]}

  if [ $nb_words -eq 1 ]; then
    echo "$args"
    return 0
  fi

  fzf $@ <<< $(xargs -n1 <<< "$args")
}

_install_fzf()
(
  set -e
  __prepare_local_install

  # fzf

  local fzf_path="$APT_DIR/fzf"

  if [ -e $fzf_path ]; then
    git -C $fzf_path pull
  else
    git clone --depth 1 https://github.com/junegunn/fzf.git $fzf_path
  fi

  $fzf_path/install
  eval "$(fzf --bash)"

  # fzf-git

  local fzf_git_path="$APT_DIR/fzf-git"

  if [ -e $fzf_git_path ]; then
    git -C $fzf_git_path pull
  else
    git clone --depth 1 https://github.com/junegunn/fzf-git.sh $fzf_git_path
  fi

  . $fzf_git_path/fzf-git.sh

  if [[ ! "$PATH" == *$APT_DIR/fzf/bin* ]]; then
    export PATH="${PATH}:$APT_DIR/fzf/bin"
  fi
)

if [[ ! "$PATH" == *$APT_DIR/fzf/bin* ]]; then
  PATH="${PATH}:$APT_DIR/fzf/bin"
fi

if bin_exists fzf; then
  eval "$(fzf --bash)"
fi

if [[ -f $APT_DIR/fzf-git/fzf-git.sh ]]; then
  # the script actually exit because it takes an argument which does not exists
  __tmp_sourcing() {
    . $APT_DIR/fzf-git/fzf-git.sh
  }
  __tmp_sourcing
  unset __tmp_sourcing
fi

#
# Neovim
#

_install_nvim()
(
  set -e
  __prepare_local_install

  local _nvim_ver=${1:-v0.10.0}

  echo "Installing neovim version $_nvim_ver"

  mkdir -p $HOME/.local/bin
  curl https://github.com/neovim/neovim/releases/download/$_nvim_ver/nvim.appimage --output $HOME/.local/bin
  chmod +x $HOME/.local/bin/nvim.appimage
  mv $HOME/.local/bin/nvim.appimage $HOME/.local/bin/nvim

  mkdir -p $HOME/.config/nvim
  curl https://raw.githubusercontent.com/nvim-lua/kickstart.nvim/master/init.lua --output $HOME/.config/nvim/init.lua

  echo "Use :Mason to install code servers"
)

#
# Rg (cli ripgrep better grep)
#

_install_rg()
{
  if is_ubuntu; then
    local rg_arch_file
    local rg_arch_ext
    local rg_version="14.1.0"
    local arch="$(uname -m)"
    if [ "$arch" = "amd64" ] || [ "$arch" = "x86_64" ]; then
      rg_arch_ext=".deb"
      rg_arch_file="ripgrep_${rg_version}-1_amd64"
    else
      rg_arch_ext=".tar.gz"
      rg_arch_file="ripgrep-${rg_version}-${arch}-unknown-linux-gnu"
    fi
    (
        set -e
        cd /tmp
        curl -LO "https://github.com/BurntSushi/ripgrep/releases/download/${rg_version}/${rg_arch_file}${rg_arch_ext}" --fail-with-body
        if [ "${rg_arch_ext}" = ".deb" ]; then
          sudo dpkg -i "/tmp/${rg_arch_file}${rg_arch_ext}"
        else
          tar -xzf "/tmp/${rg_arch_file}${rg_arch_ext}" -C /tmp
          sudo cp /tmp/${rg_arch_file}/rg /usr/local/bin
        fi
    )
  else
    __pkg_manager_install ripgrep
  fi
}

if bin_exists rg; then
    export FZF_DEFAULT_COMMAND="rg --files --hidden -g '!.git'"
    export FZF_CTRL_T_COMMAND="rg --files --hidden -g '!.git'"
fi

#
# Neofetch (OS and hardware data)
#

_install_neofetch()
(
  set -e
  __prepare_local_install

  if [ -d $APT_DIR/neofetch ]; then
    cd $APT_DIR/neofetch
    git checkout 7.1.0
    git pull
  else
    git clone --depth 1 --branch 7.1.0 https://github.com/dylanaraps/neofetch.git $APT_DIR/neofetch
    cd $APT_DIR/neofetch
  fi

  local opt_sudo
  if bin_exists sudo; then opt_sudo="sudo"; fi

  $opt_sudo make install
)

#
# Figlet (cli text to ascii)
#

_install_figlet()
{
  __pkg_manager_install figlet
  # Fonts:
  # $> ls /usr/share/figlet/ | grep flf
}

#
# Lolcat (cli gradiant colored text)
#

_install_lolcat()
{
  __pkg_manager_install lolcat
}

#
# Asciinema (record and play terminal sessions)
#

_install_asciinema()
{
  __pkg_manager_install asciinema
}

#
# GdbInit
#

_install_gdb_init()
{
  if [ -f ~/.gdbinit ]; then
    mv ~/.gdbinit ~/.gdbinit.old
  fi
  wget -P ~ https://github.com/cyrus-and/gdb-dashboard/raw/master/.gdbinit
  # get coloration:
  # pip install pygments
}

#
# Hyperfine (Benchmarker)
#

_install_hyperfine()
{
  if is_ubuntu; then
    (
      cd /tmp && \
      curl -LO https://github.com/sharkdp/hyperfine/releases/download/v1.16.1/hyperfine_1.16.1_amd64.deb && \
      sudo dpkg -i /tmp/hyperfine_1.16.1_amd64.deb
    )
  else
    __pkg_manager_install hyperfine
  fi
}

#
# Exiftool (better file - get info or metadata on files)
#

_install_exiftool()
(
  set -e
  __prepare_local_install

  if [ ! -d "$APT_DIR/exiftool" ]; then
    git clone --depth 1 --branch 12.94 https://github.com/exiftool/exiftool.git $APT_DIR/exiftool
  fi
  cd $APT_DIR/exiftool
  perl Makefile.PL
  make

  local opt_sudo
  if bin_exists sudo; then opt_sudo="sudo"; fi

  $opt_sudo make install
)

#
# Duf (better df)
#

_install_duf()
{
  __pkg_manager_install duf 1>/dev/null 2>/dev/null

  if [ $? -ne 0 ]; then
    go install github.com/muesli/duf@latest
  fi
}

#
# Eza (better ls)
#

_install_eza()
{
  __pkg_manager_install eza 1>/dev/null 2>/dev/null

  if [ $? -ne 0 ]; then
    __cargo_install eza https://github.com/eza-community/eza.git v0.19.1
  fi
}

alias bls="eza --long --tree --level 4 --total-size --binary --header --group --icons=always"
alias blsa="bls -A"

#
# Nerdfonts
#

_install_nerdfonts()
(
  if is_wsl; then
    mkdir -p /tmp/nerdfont
    cd /tmp/nerdfont
    wget https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/CascadiaMono.zip
    unzip CascadiaMono.zip
    open_explorer .
  else
    mkdir -p ~/.local/share/fonts
    cd ~/.local/share/fonts
    wget https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/CascadiaMono.zip
    unzip CascadiaMono.zip
    fc-cache -fv
    rm CascadiaMono.zip
  fi
)

#
# ncdu (ncurses du)
#

_install_ncdu()
{
  __pkg_manager_install ncdu
}
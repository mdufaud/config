export APT_DIR="$HOME/apt"

__prepare_local_install()
{
  mkdir -p $APT_DIR
}

__install_with_pkgmanager()
{
  if bin_exists pacman; then
    sudo pacman -S $1
  elif bin_exists pkg; then
    sudo pkg install $1
  elif bin_exists apt; then
    sudo apt install $1
  elif bin_exists apk; then
    sudo apk add $1
  elif bin_exists dnf; then
    sudo dnf install $1
  elif bin_exists brew; then
    sudo brew install $1
  fi
}

#
# Cargo
#

__install_with_cargo()
(
   __prepare_local_install

  local projname="$1"
  local github_url="$2"
  local tag_name="$3"

  if [ -n $tag_name ]; then
    tag_name="--branch $tag_name"
  fi

  git clone --depth 1 $tag_name $github_url $APT_DIR/$projname
  cd $APT_DIR/$projname
  cargo install --path .
)

if [[ ! "$PATH" == *$HOME/.cargo/bin* ]]; then
  PATH="${PATH}:$HOME/.cargo/bin"
fi

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
{
  __install_with_pkgmanager bat
  ln -s /usr/bin/batcat ~/.local/bin/bat
}

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
# Fzf (cli fuzzy finder)
#

_install_fzf()
{
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
}

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
# Rg (cli ripgrep better grep)
#

_install_rg()
{
  if is_ubuntu; then
    (
      cd /tmp && \
      curl -LO https://github.com/BurntSushi/ripgrep/releases/download/14.1.0/ripgrep_14.1.0-1_amd64.deb && \
      sudo dpkg -i /tmp/ripgrep_14.1.0-1_amd64.deb
    )
  else
    __install_with_pkgmanager ripgrep
  fi
}

if bin_exists rg; then
    export FZF_DEFAULT_COMMAND="rg --files --hidden -g '!debugfs' -g '!.git'"
    export FZF_CTRL_T_COMMAND="rg --files --hidden -g '!debugfs' -g '!.git'"
fi

#
# Neofetch (OS and hardware data)
#

_install_neofetch()
(
  __install_with_cargo neofetch https://github.com/dylanaraps/neofetch.git 7.1.0
)

#
# Figlet (cli text to ascii)
#

_install_figlet()
{
  __install_with_pkgmanager figlet
  # Fonts:
  # $> ls /usr/share/figlet/ | grep flf
}

#
# Lolcat (cli gradiant colored text)
#

_install_lolcat()
{
  __install_with_pkgmanager lolcat
}

#
# Asciinema (record and play terminal sessions)
#

_install_asciinema()
{
  __install_with_pkgmanager asciinema
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
# Dog (DNS tool)
#

_install_dog()
(
  __install_with_cargo dog https://github.com/ogham/dog.git
)

#
# Tre (better tree)
#

_install_tre()
(
  __install_with_cargo tre https://github.com/dduan/tre.git v0.4.0
)

#
# Bandwhich (check network usage)
#

_install_bandwhich()
{
  __install_with_cargo bandwhich https://github.com/imsnif/bandwhich.git v0.23.0
  sudo setcap cap_sys_ptrace,cap_dac_read_search,cap_net_raw,cap_net_admin+ep $(command -v bandwhich)
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
    __install_with_pkgmanager hyperfine
  fi
}

#
# Exiftool (better file - get info or metadata on files)
#

_install_exiftool()
(
  __prepare_local_install

  git clone --depth 1 --branch 12.94 https://github.com/exiftool/exiftool.git $APT_DIR/exiftool
  $APT_DIR/exiftool
  perl Makefile.PL
  make
  make install
)

#
# Duf (better df)
#

_install_duf()
{
  __install_with_pkgmanager duf
}

#
# Eza (better ls)
#

_install_eza()
{
  __install_with_pkgmanager eza 1>/dev/null 2>/dev/null

  if [ $? -ne 0 ]; then
    __install_with_cargo eza https://github.com/eza-community/eza.git v0.19.1
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
    xdg-open https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/CascadiaMono.zip
    local windows_current_username=$(powershell.exe '$env:UserName' | tr -d '\r' | tr -d '\n')
    open_explorer /mnt/c/Users/$windows_current_username/Downloads
  else
    mkdir -p ~/.local/share/fonts
    cd ~/.local/share/fonts
    wget https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/CascadiaMono.zip
    unzip CascadiaMono.zip
    fc-cache -fv
  fi
)

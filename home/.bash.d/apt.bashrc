export APT_DIR="$HOME/apt"
export APT_BIN_DIR="${APT_DIR}/bin"
export APT_LOCAL_BIN_DIR="$HOME/.local/bin"

PATH="${PATH}:${APT_BIN_DIR}:${APT_LOCAL_BIN_DIR}"

function install_list()
(
  set -e

  if ! bin_exists fzf; then
    _install_fzf
  fi

  local list="$(declare -F | grep _install_ | sed 's/declare -f //g')"
  local selection
  selection="$(fzf --multi --cycle <<< "$list")"

  for cmd in ${selection}; do 
    echo "$cmd"
    $cmd
  done
)

__prepare_local_install()
{
  mkdir -p "${APT_BIN_DIR}"
  mkdir -p "${APT_LOCAL_BIN_DIR}"
}

export PKG_MANAGER=""
export PKG_MANAGER_INSTALL_CMD=""

__pkg_manager_setup()
{
  if [ -z "$PKG_MANAGER" ]; then
    if bin_exists pacman; then
      PKG_MANAGER="pacman"
      PKG_MANAGER_INSTALL_CMD="-S --noconfirm"
    elif bin_exists pkg; then
      PKG_MANAGER="pkg"
      PKG_MANAGER_INSTALL_CMD="install -y"
    elif bin_exists apt; then
      PKG_MANAGER="apt"
      PKG_MANAGER_INSTALL_CMD="install -y"
    elif bin_exists apk; then
      PKG_MANAGER="apk"
      PKG_MANAGER_INSTALL_CMD="add --no-cache"
    elif bin_exists dnf; then
      PKG_MANAGER="dnf"
      PKG_MANAGER_INSTALL_CMD="install -y"
    elif bin_exists brew; then
      PKG_MANAGER="brew"
      PKG_MANAGER_INSTALL_CMD="install"
    else
      print_error "No package manager found"
      return 1
    fi
  fi

  local opt_sudo
  if bin_exists sudo; then
    opt_sudo="sudo "
  fi

  PKG_MANAGER="${opt_sudo}${PKG_MANAGER}"
}

__pkg_manager_install()
{
  __pkg_manager_setup
  $PKG_MANAGER $PKG_MANAGER_INSTALL_CMD $@
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

#
# GitHub CLI (gh)
#

if bin_exists gh; then

# list PRs: number, state, branch, title, last commit
gh_prs()
{
  gh pr list --state "${1:-open}" --json number,headRefName,title,state,commits \
    --template '{{range .}}#{{.number}} [{{.headRefName}}] {{.title}} ({{(index .commits (sub (len .commits) 1)).messageHeadline}}){{"\n"}}{{end}}'
}

# fzf-select a PR and checkout
gh_pr_checkout()
{
  local pr
  pr=$(gh pr list --json number,headRefName,title --template '{{range .}}{{.number}}\t{{.headRefName}}\t{{.title}}{{"\n"}}{{end}}' \
    | fzf --delimiter='\t' --with-nth=1,2,3 --preview 'gh pr view {1} --comments' \
    | cut -f1)
  [ -n "$pr" ] && gh pr checkout "$pr"
}
alias ghco="gh_pr_checkout"

# fzf-select a PR and view diff
gh_pr_diff()
{
  local pr
  pr=$(gh pr list --state "${1:-open}" --json number,headRefName,title --template '{{range .}}{{.number}}\t{{.headRefName}}\t{{.title}}{{"\n"}}{{end}}' \
    | fzf --delimiter='\t' --with-nth=1,2,3 --preview 'gh pr diff {1} --color=always | head -200' \
    | cut -f1)
  [ -n "$pr" ] && gh pr diff "$pr" --color=always | less -R
}

# list my open PRs and issues across repos
gh_my()
{
  echo "=== PRs ==="
  gh search prs --author=@me --state=open --json repository,number,title,updatedAt \
    --template '{{range .}}{{.repository.nameWithOwner}}#{{.number}} {{.title}} ({{timefmt "2006-01-02" .updatedAt}}){{"\n"}}{{end}}'
  echo "=== Issues ==="
  gh search issues --assignee=@me --state=open --json repository,number,title,updatedAt \
    --template '{{range .}}{{.repository.nameWithOwner}}#{{.number}} {{.title}} ({{timefmt "2006-01-02" .updatedAt}}){{"\n"}}{{end}}'
}

# CI runs: fzf-select and view logs
gh_runs()
{
  local run
  run=$(gh run list --limit 20 --json databaseId,status,conclusion,name,headBranch,createdAt \
    --template '{{range .}}{{.databaseId}}\t{{.status}}\t{{.conclusion}}\t{{.headBranch}}\t{{.name}}\t{{timefmt "01-02 15:04" .createdAt}}{{"\n"}}{{end}}' \
    | fzf --delimiter='\t' --with-nth=2,3,4,5,6 --preview 'gh run view {1}' \
    | cut -f1)
  [ -n "$run" ] && gh run view "$run" --log | less -R
}

# watch current branch CI
gh_run_watch()
{
  local run
  run=$(gh run list --branch "$(git branch --show-current)" --limit 1 --json databaseId --template '{{(index . 0).databaseId}}')
  [ -n "$run" ] && gh run watch "$run" --exit-status
}

# search code on github
gh_search()
{
  _arg_assert_exists "$1" "gh_search <query> [language]" || return
  local query="$1"
  [ -n "$2" ] && query="$query language:$2"
  gh search code "$query" --json repository,path,textMatches \
    --template '{{range .}}{{.repository.nameWithOwner}}/{{.path}}{{"\n"}}{{range .textMatches}}  {{.fragment}}{{"\n"}}{{end}}{{end}}' | head -80
}

# quick PR create from current branch
gh_pr_create()
{
  gh pr create --fill --web "$@"
}
alias ghprc="gh_pr_create"

# view repo info
gh_repo()
{
  gh repo view --json name,description,stargazerCount,forkCount,defaultBranchRef,languages \
    --template '{{.name}} ⭐{{.stargazerCount}} 🍴{{.forkCount}} [{{.defaultBranchRef.name}}]{{"\n"}}{{.description}}{{"\n"}}{{range .languages.edges}}{{.node.name}} {{end}}{{"\n"}}'
}

# notifications
gh_notif()
{
  gh api notifications --jq '.[] | "\(.repository.full_name) \(.subject.type): \(.subject.title)"' | head -30
}

fi

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
    rm -f ${APT_LOCAL_BIN_DIR}/bat
    ln -s $(command -v batcat) ${APT_LOCAL_BIN_DIR}/bat
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
  valgrind --tool=cachegrind $@ &
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
  valgrind --tool=callgrind $@ &
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

  local fzf_path="${APT_DIR}/fzf"

  if [ -e $fzf_path ]; then
    git -C $fzf_path pull
  else
    git clone --depth 1 https://github.com/junegunn/fzf.git $fzf_path
  fi

  $fzf_path/install
  eval "$(fzf --bash)"

  # fzf-git

  local fzf_git_path="${APT_DIR}/fzf-git"

  if [ -e $fzf_git_path ]; then
    git -C $fzf_git_path pull
  else
    git clone --depth 1 https://github.com/junegunn/fzf-git.sh $fzf_git_path
  fi

  . $fzf_git_path/fzf-git.sh
)

if [[ ! "$PATH" == *${APT_DIR}/fzf/bin* ]]; then
  PATH="${PATH}:${APT_DIR}/fzf/bin"
fi

if bin_exists fzf; then
  eval "$(fzf --bash)"
fi

if [[ -f ${APT_DIR}/fzf-git/fzf-git.sh ]]; then
  # the script actually exit because it takes an argument which does not exists
  __tmp_sourcing() {
    . ${APT_DIR}/fzf-git/fzf-git.sh
  }
  __tmp_sourcing
  unset __tmp_sourcing
fi

#
# Neovim
#

_install_nvim()
(
  __prepare_local_install

  local nvim_ver=${1:-v0.10.4}

  echo "Installing neovim version $nvim_ver"

  local arch="$(uname -m)"
  if [ "$arch" = "aarch64" ]; then
    arch="arm64"
  else
    arch="x86_64"
  fi
  local nvim_file="nvim-linux-${arch}.appimage"

  curl -L "https://github.com/neovim/neovim/releases/download/${nvim_ver}/${nvim_file}" \
    --output "${APT_LOCAL_BIN_DIR}/nvim.appimage" \
    --fail-with-body
  chmod +x ${APT_LOCAL_BIN_DIR}/nvim.appimage

  __pkg_manager_install libfuse2

  if ${APT_LOCAL_BIN_DIR}/nvim.appimage -v 1>/dev/null 2>/dev/null; then
    mv ${APT_LOCAL_BIN_DIR}/nvim.appimage ${APT_LOCAL_BIN_DIR}/nvim
  else
    # cannot use libfuse - extracting package
    (
      set -e
      cd ${APT_DIR}
      mv ${APT_LOCAL_BIN_DIR}/nvim.appimage nvim.appimage
      ./nvim.appimage --appimage-extract
      # TODO: glibc error not foud
      ./squashfs-root/AppRun --version
      mv squashfs-root nvim
      ln -s nvim/AppRun ${APT_LOCAL_BIN_DIR}/nvim
    )
  fi

  mkdir -p $HOME/.config/nvim
  curl -L https://raw.githubusercontent.com/nvim-lua/kickstart.nvim/master/init.lua \
    --output $HOME/.config/nvim/init.lua \
    --fail-with-body


  echo "Use :Mason to install code servers"
)

#
# Neofetch (OS and hardware data)
#

_install_neofetch()
(
  set -e
  __prepare_local_install

  if [ -d ${APT_DIR}/neofetch ]; then
    cd ${APT_DIR}/neofetch
    git checkout 7.1.0
    git pull
  else
    git clone --depth 1 --branch 7.1.0 https://github.com/dylanaraps/neofetch.git ${APT_DIR}/neofetch
    cd ${APT_DIR}/neofetch
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
# perf
#

_perf_check_dwarf_support()
{
  if ! bin_exists perf; then
    echo "perf not found" >&2
    return 1
  fi

  # Try a no-op record to test DWARF support (silently)
  if perf record -g --call-graph dwarf true -o /dev/null 2>/dev/null; then
    return 0
  fi

  echo "perf does not support '--call-graph dwarf' on this system" >&2
  return 2
}
perf_attach()
{
  _arg_assert_exists "$1" "perf_attach <pid> [out.data]" || return
  local pid="$1"
  local tmpdir
  tmpdir=$(mktemp -d 2>/dev/null || mktemp -d -t perf)
  echo "Temp dir: $tmpdir"
  cd "$tmpdir" || return
  local out="${2:-${tmpdir}/perf-${pid}.data}"

  _perf_check_dwarf_support || return

  echo "Recording perf (DWARF) on pid $pid -> $out (Ctrl-C to stop)"
  perf record -g --call-graph dwarf -p "$pid" -o "$out"
  echo "Recording finished: $out"
}

perf_cmd()
{
  _arg_assert_exists "$1" "perf_cmd <cmd> [out.data]" || return
  local tmpdir
  tmpdir=$(mktemp -d 2>/dev/null || mktemp -d -t perf)
  echo "Temp dir: $tmpdir"
  cd "$tmpdir" || return
  local out="${2:-${tmpdir}/perf-cmd.data}"

  _perf_check_dwarf_support || return

  echo "Recording command under perf (DWARF) -> $out"
  perf record -g --call-graph dwarf -o "$out" -- "$@"
  echo "Recording finished: $out"
}

perf_report()
{
  _arg_assert_exists "$1" "perf_report <perf.data>" || return
  local data="$1"

  if ! bin_exists perf; then
    echo "perf not found" >&2
    return 1
  fi

  echo "Opening perf report for $data"
  perf report -g --stdio -i "$data"
}

#
# gdb
#

gdb_bt()
{
  gdb -ex "set pagination off" -ex "thread apply all bt full" -ex "quit" --args "$@"
}

gdb_bt_attach()
{
  _arg_assert_exists "$1" "gdb_bt_attach <pid>" || return
  local pid="$1"
  shift
  gdb -ex "set pagination off" -ex "thread apply all bt full" -ex "quit" --pid "$pid" "$@"
}

gdb_catch()
{
  gdb -ex "handle SIGHUP nostop noprint nopass" -ex "handle SIGPIPE nostop noprint nopass" -ex "catch throw" -ex "run" --args "$@"
}

gdb_catch_attach()
{
  _arg_assert_exists "$1" "gdb_catch_attach <pid>" || return
  local pid="$1"
  shift
  gdb -ex "handle SIGHUP nostop noprint nopass" -ex "handle SIGPIPE nostop noprint nopass" -ex "catch throw" -ex "run" --pid "$pid" "$@"
}

_install_gdb_init()
{
  if [ -f ~/.gdbinit ]; then
    if [ -f ~/.gdbinit.old ]; then
      print_error "You already have a .gdbinit.old file"
      return 1
    fi
    echo "Moving current .gdbinit to .gdbinit.old"
    mv ~/.gdbinit ~/.gdbinit.old
  fi
  wget -P ~ https://github.com/cyrus-and/gdb-dashboard/raw/master/.gdbinit
  # get coloration:
  # pip install pygments
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
  sudo make install
)

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
    explorer .
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

#
# qemu
#

qemu_img_create()
{
  _arg_assert_exists "$1" "qemu_img_create <path> <size> [backing_file]" || return
  _arg_assert_exists "$2" "qemu_img_create <path> <size> [backing_file]" || return

  local img="$1" size="$2" backing="$3"
  if [[ -n "$backing" ]]; then
    qemu-img create -f qcow2 -b "$backing" "$img" "$size"
  else
    qemu-img create -f qcow2 "$img" "$size"
  fi
}

qemu_convert()
{
  _arg_assert_exists "$1" "qemu_convert <src> <dst> [format]" || return
  _arg_assert_exists "$2" "qemu_convert <src> <dst> [format]" || return

  local src="$1" dst="$2" fmt="${3:-qcow2}"
  qemu-img convert -f auto -O "$fmt" "$src" "$dst"
}

_qemu_default_arch()
{
  local cur
  cur="$(uname -m)"
  case "$cur" in
    x86_64) echo "x86_64" ;;
    aarch64) echo "aarch64" ;;
    i686|i386) echo "i386" ;;
    *) echo "$cur" ;;
  esac
}

qemu_start()
{
  _arg_assert_exists "$1" "qemu_start <image> [arch] [mem] [cpus] [ssh_port] [bg] [iso]" || return

  local img="$1"
  local arch="$2"
  local mem="$3"
  local cpus="$4"
  local ssh_port="$5"
  local bg_flag="$6"
  local iso="$7"

  # Interactive architecture selection with fzf (pre-filled with current arch)
  if [[ -z "$arch" ]]; then
    if bin_exists fzf; then
      local curarch
      curarch="$(_qemu_default_arch)"
      arch=$(printf "%s\n" "x86_64" "aarch64" "i386" | fzf --height 6 --query "$curarch" --prompt "Choose architecture: ")
    else
      arch="$(_qemu_default_arch)"
    fi
  fi

  # Interactive memory and cpu selection with gum (fallback to defaults)
  if [[ -z "$mem" ]]; then
    if bin_exists gum; then
      mem=$(gum input --value "2G" --prompt "Memory (e.g. 2G):")
    else
      mem="2G"
    fi
  fi

  if [[ -z "$cpus" ]]; then
    if bin_exists gum; then
      cpus=$(gum input --value "2" --prompt "CPUs:")
    else
      cpus="2"
    fi
  fi

  # Choose qemu binary based on arch
  local qemu_bin
  case "$arch" in
    x86_64) qemu_bin="qemu-system-x86_64" ;;
    aarch64|arm64) qemu_bin="qemu-system-aarch64" ;;
    i386|i686) qemu_bin="qemu-system-i386" ;;
    *) qemu_bin="qemu-system-x86_64" ;;
  esac

  _arg_assert_binary "$qemu_bin" "$qemu_bin not found" || return

  # Build network options with optional SSH port forwarding
  local netdev_opts=""
  if [[ -n "$ssh_port" ]]; then
    netdev_opts=",hostfwd=tcp::${ssh_port}-:22"
  fi

  # Build command safely as an array
  local drive_opts="file=${img},if=virtio,cache=none"
  local qemu_cmd
  qemu_cmd=("$qemu_bin" "-m" "$mem" "-smp" "$cpus" "-drive" "$drive_opts" "-device" "virtio-net-pci,netdev=net0" "-netdev" "user,id=net0${netdev_opts}" "-enable-kvm")

  if [[ -n "$iso" ]]; then
    qemu_cmd+=("-cdrom" "$iso")
  fi

  if [[ "$bg_flag" == "bg" || "$bg_flag" == "daemon" ]]; then
    qemu_cmd+=("-daemonize" "-display" "none")
  else
    qemu_cmd+=("-nographic")
  fi

  echo "Starting VM: ${qemu_cmd[*]}"
  "${qemu_cmd[@]}"
}

qemu_ssh()
{
  _arg_assert_exists "$1" "qemu_ssh <port> [user]" || return
  local port="$1" user="${2:-root}"
  ssh -o StrictHostKeyChecking=no -p "$port" "${user}@127.0.0.1"
}

qemu_mount_image()
{
  _arg_assert_exists "$1" "qemu_mount_image <image> [partition-num]" || return

  local img="$1" partnum="${2:-1}" nbd="/dev/nbd0" mp="/mnt/qemu_img"
  sudo modprobe nbd max_part=16
  sudo qemu-nbd --connect="$nbd" "$img"
  sleep 0.5
  sudo partprobe "$nbd" || true

  local devpart="${nbd}p${partnum}"
  if [[ ! -b "$devpart" ]]; then
    devpart="${nbd}${partnum}"
  fi
  if [[ ! -b "$devpart" ]]; then
    echo "Partition ${partnum} not found on ${nbd}" >&2
    return 2
  fi
  sudo mkdir -p "$mp"
  sudo mount "$devpart" "$mp"
  echo "Image mounted on $mp (device: $devpart)"
}

qemu_unmount_image()
{
  local nbd="${1:-/dev/nbd0}" mp="${2:-/mnt/qemu_img}"
  if mountpoint -q "$mp"; then
    sudo umount "$mp"
    sudo rmdir --ignore-fail-on-non-empty "$mp" || true
  fi
  sudo qemu-nbd --disconnect "$nbd" || true
  echo "Disconnected: $nbd"
}

qemu_snapshot_create()
{
  _arg_assert_exists "$1" "qemu_snapshot_create <image> <name>" || return
  _arg_assert_exists "$2" "qemu_snapshot_create <image> <name>" || return
  qemu-img snapshot -c "$2" "$1"
}

qemu_snapshot_list()
{
  _arg_assert_exists "$1" "qemu_snapshot_list <image>" || return
  qemu-img snapshot -l "$1"
}

qemu_snapshot_delete()
{
  _arg_assert_exists "$1" "qemu_snapshot_delete <image> <name>" || return
  _arg_assert_exists "$2" "qemu_snapshot_delete <image> <name>" || return
  qemu-img snapshot -d "$2" "$1"
}

qemu_list_images()
{
  local dir="${1:-.}"
  find "$dir" -maxdepth 3 -type f \( -iname '*.qcow2' -o -iname '*.img' -o -iname '*.raw' \) -print
}

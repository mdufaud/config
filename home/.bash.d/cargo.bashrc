#
# Cargo
#

__cargo_install()
(
   __prepare_local_install

  if ! bin_exists cargo; then
    __pkg_manager_install cargo
    if [[ ! "$PATH" == *$HOME/.cargo/bin* ]]; then
      export PATH="${PATH}:$HOME/.cargo/bin"
    fi
  fi

  local projname="$1"

  local github_url="$2"
  if ! is_http "$github_url"; then
    cargo install "$@"
    return
  fi

  local tag_name="$3"
  if [ -n "$tag_name" ]; then
    tag_name="--branch $tag_name"
  fi

  if [ ! -d $APT_DIR/$projname ]; then
    git clone --depth 1 $tag_name $github_url $APT_DIR/$projname
    cd $APT_DIR/$projname
  else
    cd $APT_DIR/$projname
    if [ -n "$tagname" ]; then
      git checkout $tag_name
    fi
    git pull
  fi

  cargo install --path .
)

if [[ ! "$PATH" == *$HOME/.cargo/bin* ]]; then
  PATH="${PATH}:$HOME/.cargo/bin"
fi

#
# Dog (DNS tool)
#

_install_dog()
(
  __cargo_install dog https://github.com/ogham/dog.git
)

#
# Tre (better tree)
#

_install_tre()
(
  __cargo_install tre https://github.com/dduan/tre.git v0.4.0
)

#
# Bandwhich (check network usage)
#

_install_bandwhich()
{
  __cargo_install bandwhich https://github.com/imsnif/bandwhich.git v0.23.0
  sudo setcap cap_sys_ptrace,cap_dac_read_search,cap_net_raw,cap_net_admin+ep $(command -v bandwhich)
}

#
# Delta (difftool)
#

_install_delta()
{
  __cargo_install git-delta
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
# Hyperfine (Benchmarker)
#

_install_hyperfine()
{
  __cargo_install --version 1.16.1 hyperfine
}

#
# Rg (cli ripgrep better grep)
#

_install_rg()
{
  __cargo_install --version 14.1.0 ripgrep
  export FZF_DEFAULT_COMMAND="rg --files --hidden -g '!.git'"
  export FZF_CTRL_T_COMMAND="rg --files --hidden -g '!.git'"
}

if bin_exists rg; then
    export FZF_DEFAULT_COMMAND="rg --files --hidden -g '!.git'"
    export FZF_CTRL_T_COMMAND="rg --files --hidden -g '!.git'"
fi

#
# Cargo
#

__cargo_assert_installed()
{
  if ! bin_exists cargo; then
    __pkg_manager_install cargo
  fi
}

__cargo_install()
(
   __prepare_local_install
   __cargo_assert_installed

  if ! bin_exists cargo; then
    __pkg_manager_install cargo
  fi

  local projname="$1"
  local github_url="$2"
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
  if ! bin_exists cargo; then
    __pkg_manager_install cargo
  fi
  cargo install git-delta
}
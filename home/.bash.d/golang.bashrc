#
# Golang
#

__go_install()
{
   __prepare_local_install

  if ! bin_exists go; then
    # Install latest go version
    local go_version="1.20"
    local go_tarname
    local arch="$(uname -m)"
    if [ "$arch" = "aarch64" ]; then
      go_tarname="go${go_version}.linux-arm64.tar.gz"
    else
      go_tarname="go${go_version}.linux-amd64.tar.gz"
    fi

    (
      mkdir -p $HOME/apt \
        && cd /tmp \
        && wget "https://golang.org/dl/$go_tarname" \
        && tar -C $HOME/apt -xzf "$go_tarname" \
        && rm "$go_tarname"
    )

    export GO111MODULE=on
    export GOROOT="$HOME/apt/go"
    export GOPATH="$HOME/.go"
    if [[ ! "$PATH" == *${GOROOT}/bin:${GOPATH}/bin* ]]; then
      export PATH="${PATH}:${GOROOT}/bin:${GOPATH}/bin"
    fi
    mkdir -p "$GOPATH"
  fi

  go install $@
}

if bin_exists go; then
  export GO111MODULE=on
  export GOROOT="$HOME/apt/go"
  export GOPATH="$HOME/.go"
  if [[ ! "$PATH" == *${GOROOT}/bin:${GOPATH}/bin* ]]; then
    export PATH="${PATH}:${GOROOT}/bin:${GOPATH}/bin"
  fi
  mkdir -p "$GOPATH"
fi

#
# LF file explorer
#

function _install_lf() {
  if ! bin_exists lf; then
      env CGO_ENABLED=0 __go_install -ldflags="-s -w" github.com/gokcehan/lf@r33
  fi
}

#
# qrcode_terminal
#

function _install_qrcode_terminal()
{
  # no tags
  __go_install github.com/dawndiy/qrcode-terminal@latest
}

#
# Charm (CLI suite)
#

function _install_charm() {
  # Markdown reader
  __go_install github.com/charmbracelet/glow@v1.5.1
  __go_install github.com/charmbracelet/gum@v0.13.0
}

#
# YQ (yaml's jq)
#

_install_yq()
{
  __go_install github.com/mikefarah/yq@v4.45.1
}


if bin_exists gum; then
  # export GUM_INPUT_CURSOR_FOREGROUND="#FF0"
  # export GUM_INPUT_PROMPT_FOREGROUND="#0FF"
  # export GUM_INPUT_PLACEHOLDER="Type something..."
  export GUM_INPUT_PROMPT="> "
  export GUM_INPUT_WIDTH=80

  export GUM_SPIN_SPINNER="dot"
  function gum_choose_spin() {
    export GUM_SPIN_SPINNER=$(gum choose --height 11 line dot minidot jump pulse points globe moon monkey meter hamburger)
  }

  function gum_check_spins() {
      for __spinner in line dot minidot jump pulse points globe moon monkey meter hamburger; do
        gum spin --spinner=$__spinner --title="Loading with $__spinner..." --show-output sleep 1
      done
      unset __spinner
  }

  function gum_card() {
    _arg_assert_exists "$1" "usage: gum_card msg..." || return

    gum style \
    --foreground \#4169E1 \
    --border-foreground \#E1B941 \
    --border double \
    --align left \
    --margin "0 1 1 1" \
    --padding "0 1" \
    -- "$@"
  }
fi
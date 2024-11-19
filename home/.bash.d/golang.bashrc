#
# Golang
#

if [ -d "$HOME/apt/go" ]; then
  PATH="$HOME/apt/go/bin:$PATH"
fi

if [ -x "$(command -v go)" ]; then
  export GOPATH=$HOME/.go
  PATH="$GOPATH/bin:$PATH"
fi

#
# Installers
#

#
# LF file explorer
#

function _install_lf() {
  _arg_assert_binary go "golang is not installed" || return

  if ! bin_exists lf; then
      env CGO_ENABLED=0 go install -ldflags="-s -w" github.com/gokcehan/lf@latest
  else
    print_err "LF already installed"
  fi
}

#
# qrcode_terminal
#

function _install_qrcode_terminal()
{
  _arg_assert_binary go "golang is not installed" || return

  go install github.com/dawndiy/qrcode-terminal@latest
}

#
# Charm (CLI suite)
#

function _install_charm() {
  _arg_assert_binary go "golang is not installed" || return

  # Markdown reader
  go install github.com/charmbracelet/glow@v1.5.1
  # cd $HOME/apt && wget https://golang.org/dl/go1.20.linux-amd64.tar.gz
  go install github.com/charmbracelet/gum@v0.13.0
}

#
# YQ (yaml's jq)
#

_install_yq()
{
  _arg_assert_binary go "golang is not installed" || return

  go install github.com/mikefarah/yq/v4@latest
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
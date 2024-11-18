#!/bin/bash

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

# Source global definitions
if [ -f /etc/bashrc ]; then
  . /etc/bashrc
fi

if [ -f ~/.bash_aliases ]; then
  . ~/.bash_aliases
fi

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi

# User specific environment

# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/bin" ]; then
  PATH="$HOME/bin:$PATH"
fi

# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/.local/bin" ]; then
  PATH="$HOME/.local/bin:$PATH"
fi

# Uncomment the following line if you don't like systemctl's auto-paging feature:
# export SYSTEMD_PAGER=

#
# Configurations
#

tabs 2

export TERM=xterm-256color
export EDITOR="vim"

# Use extra globing features. See man bash, search extglob
shopt -s extglob
# Include .files when globbing
shopt -s dotglob
# When a glob expands to nothing, make it an empty string instead of the literal characters
shopt -s nullglob
# Fix spelling errors for cd, only in interactive shell
shopt -s cdspell

# Check the window size after each command and, if necessary, update the values of LINES and COLUMNS
shopt -s checkwinsize

#
# History
#

# Expand the history size
export HISTFILESIZE=10000
export HISTSIZE=500

# Sane for multibash
shopt -s histappend
# Combine multiline commands into one in history
shopt -s cmdhist

# Ignore duplicates, ls without options and builtin commands
HISTCONTROL=ignoredups
export HISTIGNORE="&:ls:[bf]g:exit"

# Allow ctrl-S for history navigation (with ctrl-R)
stty -ixon

#
# Binds
#

bind '"\e[1;2C":forward-word'
bind '"\e[1;2D":backward-word'

# If there are multiple matches for completion, Tab should cycle through them
bind 'TAB:menu-complete'

# Display a list of the matching files
bind "set show-all-if-ambiguous on"

# Perform partial (common) completion on the first Tab press, only start
# cycling full results on the second Tab press (from bash version 5)
bind "set menu-complete-display-prefix on"

# Disable the bell
bind "set bell-style visible"

#
# Aliases
#

alias ssh="ssh -YCC"

alias l="ls"
alias ll="ls -lh"
alias la="ls -lha"

# show hidden files
alias l.='ls -d .*'

alias cl="clear"
alias vi="vim"
alias gvi="gvim"

if [ -x "$(command -v python3)" ]; then
  alias py="python3"
else
  alias py="python"
fi

#
# Colors
#

# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then

    alias ls='ls --color=auto'
    alias dir='dir --color=auto'
    alias vdir='vdir --color=auto'
    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
    alias less='less -R'
    alias diff='diff --color'

    # Changes 'ls' colors
    if [ -f "$HOME/.LS_COLORS" ]; then
        eval $(dircolors -b $HOME/.LS_COLORS)
    fi

    # Color for manpages in less makes manpages a little easier to read

    # $(tput setaf x):          man terminfo (then search COLOR_BLACK)
    # LESS_TERMCAP_x=$(tput y): man terminfo

    if [ -f "$HOME/.LESS_TERMCAP" ]; then
        eval $(dircolors -b $HOME/.LESS_TERMCAP)
    else
        if [ -x "$(command -v tput)" ]; then
            export LESS_TERMCAP_mb=$(tput blink; tput setaf 2)              # begin blink
            export LESS_TERMCAP_md=$(tput bold; tput setaf 5)               # begin bold
            export LESS_TERMCAP_so=$(tput bold; tput setaf 3; tput setab 4) # begin standout mode
            export LESS_TERMCAP_us=$(tput smul; tput bold; tput setaf 7)    # begin underline
            export LESS_TERMCAP_me=$(tput sgr0)                 # reset bold/blink
            export LESS_TERMCAP_se=$(tput rmso; tput sgr0)      # reset standout mode
            export LESS_TERMCAP_ue=$(tput rmul; tput sgr0)      # reset underline
            export LESS_TERMCAP_mr=$(tput rev)      # enter reverse video mode
            export LESS_TERMCAP_mh=$(tput dim)      # turn on half‐bright mode
            export LESS_TERMCAP_ZN=$(tput ssubm)    # enter subscript mode
            export LESS_TERMCAP_ZO=$(tput ssupm)    # enter subscript mode
            export LESS_TERMCAP_ZV=$(tput rsubm)    # end subscript mode
            export LESS_TERMCAP_ZW=$(tput rsupm)    # end subscript mode
        else
            # backup
            export LESS_TERMCAP_mb=$'\e[1;31m'     # begin blink
            export LESS_TERMCAP_md=$'\e[1;33m'     # begin bold
            export LESS_TERMCAP_so=$'\e[01;44;37m' # begin standout mode
            export LESS_TERMCAP_us=$'\e[01;37m'    # begin underline
            export LESS_TERMCAP_me=$'\e[0m'        # reset bold/blink
            export LESS_TERMCAP_se=$'\e[0m'        # reset standout mode
            export LESS_TERMCAP_ue=$'\e[0m'        # reset underline
        fi
    fi

fi

# To have colors for ls and all grep commands such as grep, egrep and zgrep
export CLICOLOR=1

# Get color support for 'less'
export LESS="--RAW-CONTROL-CHARS"

# For Konsole and Gnome-terminal
export GROFF_NO_SGR=1

#
# Extra global definitions
#

if [ -d $HOME/.bash.d ]; then
  load_script()
  {
    local __path="$HOME/.bash.d/$1.bashrc"
    if [ -r "$__path" ]; then
    . "$__path"
    fi
  }

  load_script core
  load_script utils
  load_script prompt
  load_script system
  load_script network
  load_script term
  load_script convert
  load_script ssl
  load_script apt
  load_script golang
  load_script cargo

  unset load_script
fi

if [ -r $HOME/.private.bashrc ]; then
  . $HOME/.private.bashrc
fi

export PATH
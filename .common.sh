#!/bin/bash

ask_confirm()
{
  local __confirm_msg="$@"
  if [ -z "$__confirm_msg" ]; then
    __confirm_msg="Confirm"
  fi

  echo -n "$__confirm_msg (y/N): "

  local input
  read input
  case $input in
      y)
          return 0
          ;;
      Y)
          return 0
          ;;
      *)
          return 1
          ;;
  esac
}

list_targets()
{
  echo '('
  echo "[home/.bashrc]=$HOME/.bashrc"
  echo "[home/.bash.d]=$HOME/.bash.d"
  echo "[home/.LS_COLORS]=$HOME/.LS_COLORS"
  echo "[apt/.config/lf]=$HOME/.config/lf"
  echo "[apt/.gitalias]=$HOME/.gitalias"
  echo "[apt/.git.d]=$HOME/.git.d"
  echo ')'
}

print_targets()
{
  declare -A __dict="$(list_targets)"
  local output=$(for key in "${!__dict[@]}" ; do echo "$key ---> ${__dict[$key]}"; done)
  echo "$output" | sort
}

# bash way to see if script is sourced or not
(return 0 2>/dev/null) || print_targets
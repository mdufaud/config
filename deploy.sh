#!/bin/bash

ask_confirm() {
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

_replace_file() {
    local path_from="$1"
    local path_to="$2"

    if [ -z "$path_from" ]; then
        echo "Error in _replace_file() argument path_from is empty"
        return 1
    fi
    if [ -z "$path_to" ]; then
        echo "Error in _replace_file() argument path_to is empty"
        return 2
    fi

    local diff="$(diff --color=always $path_from $path_to)"
    local ret=$?
    if [ $ret -ne 0 ]; then
        echo "Difference for file $path_from:"
        echo "$diff"
        echo
        if ask_confirm "Do you want to replace $path_to ?"; then
            echo "Copying $path_from ---> $path_to"
        else
            echo "Not copying"
        fi
    fi
}

replace_from_to() {
    local path_from="$1"
    local path_to="$2"

    if [ -z "$path_from" ]; then
        echo "Error in replace_from_to() argument path_from is empty"
        return 1
    fi
    if [ -z "$path_to" ]; then
        echo "Error in replace_from_to() argument path_to is empty"
        return 2
    fi

    if [ ! -e "$path_to" ]; then
        echo $path_to does not exists - copying
        mkdir -p $(dirname $path_to)
        cp -R $path_from $path_to
        return 0
    fi

    if [ -d $path_from ]; then
        for file in $(ls -A $path_from); do
            local replace_path=$path_from/$file
            if [ -f $replace_path ]; then
                _replace_file "$replace_path" "$path_to/$file"
            else
                echo $replace_path is not a file !
            fi
        done
    elif [ -f $path_from ]; then
        _replace_file "$path_from" "$path_to"
    fi
}

replace_from_to home/.bashrc $HOME/.bashrc
replace_from_to home/.bash.d $HOME/.bash.d
replace_from_to home/.LS_COLORS $HOME/.LS_COLORS

replace_from_to apt/.config/lf $HOME/.config/lf
replace_from_to apt/.gitconfig $HOME/.gitconfig
#!/bin/bash

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)

. $SCRIPT_DIR/.common.sh

_replace_file()
{
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

  local diffstr
  diffstr=$(diff --color=always $path_to $path_from)
  local ret=$?
  # copy only if there is a difference
  if [ $ret -ne 0 ]; then
    # list differences
    echo "Difference for file $path_from:"
    echo "$diffstr"
    echo
    # ask confirmation to replace file
    if ask_confirm "Do you want to replace $path_from ---> $path_to ?"; then
      echo "Copying $path_from ---> $path_to"
      if [ -z $DRY_RUN ]; then
        cp "$path_from" "$path_to"
      fi
    else
      echo "Not copying"
    fi
  fi
}

replace_from_to()
{
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

  # if config does not exists - copy it
  if [ ! -e "$path_to" ]; then
    echo $path_to does not exists - copying
    if [ -z $DRY_RUN ]; then
      mkdir -p $(dirname $path_to)
      cp -R "$path_from" "$path_to"
    fi
    return 0
  fi

  # if config is a directory
  if [ -d "$path_from" ]; then
    for file in $(ls -A $path_from); do
      local replace_path="$path_from/$file"
      if [ -f $replace_path ]; then
        _replace_file "$replace_path" "$path_to/$file"
      else
        echo $replace_path is not a file !
      fi
    done
  # if config is a file
  elif [ -f "$path_from" ]; then
    _replace_file "$path_from" "$path_to"
  fi
}

if [ -n "$DRY_RUN" ]; then
  echo "Dry run activated"
fi

cd $SCRIPT_DIR || exit 1

declare -A targets="$(list_targets)"
for path_from in "${!targets[@]}"; do
  path_to="${targets[$path_from]}"

  replace_from_to "$path_from" "$path_to"
done
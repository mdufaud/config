#!/bin/bash

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)

. $SCRIPT_DIR/.common.sh

_do_copy()
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

  # copy only if there is a difference
  if ! diff "$path_from" "$path_to" 1>/dev/null; then
    echo "Copying $path_from ---> $path_to"
    if [ -z $DRY_RUN ]; then
      cp "$path_from" "$path_to"
    fi
  fi
}

update_into_from()
{
  local path_into="$1"
  local path_from="$2"

  if [ -z "$path_into" ]; then
    echo "Error in replace_from_to() argument path_into is empty"
    return 1
  fi
  if [ -z "$path_from" ]; then
    echo "Error in update_into_from() argument path_from is empty"
    return 2
  fi

  if [ -d "$path_from" ]; then
    for file in $(ls -A $path_from); do
      local update_path="$path_from/$file"
      local to_update_path="$path_into/$file"

      if [ -f $update_path ] ; then
        _do_copy "$update_path" "$to_update_path"
      else
        echo $update_path is not a file !
      fi
    done
  elif [ -f "$path_from" ]; then
    _do_copy "$path_from" "$path_into"
  fi
}

if [ ! -z "$DRY_RUN" ]; then
  echo "Dry run activated"
fi

cd $SCRIPT_DIR || exit 1

declare -A targets="$(list_targets)"
for path_into in "${!targets[@]}"; do
  path_from="${targets[$path_into]}"

  update_into_from "$path_into" "$path_from"
done
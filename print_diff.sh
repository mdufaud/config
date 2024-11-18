#!/bin/bash

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)

. $SCRIPT_DIR/.common.sh

cd $SCRIPT_DIR || exit 1

specific="$1"

declare -A targets="$(list_targets)"
for path_into in "${!targets[@]}"; do
  path_from="${targets[$path_into]}"

  if [ -z "$specific" ]; then
    if ! diff "$path_from" "$path_into" 1>/dev/null 2>/dev/null; then
      git diff --color-words --color=always --exit-code "$path_from" "$path_into"
    fi
  else
    if [[ $path_from == *"$specific"* ]]; then
      echo $path_from
      git diff --color-words --color=always "$path_from" "$path_into"
    fi
  fi

done
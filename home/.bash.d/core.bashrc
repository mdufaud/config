#!/bin/bash

#
# Core
#

function bash_reload()
{
  source $HOME/.bashrc
  bind -f $HOME/.inputrc
}
alias sh_reload='bash_reload'
alias shreload='bash_reload'

function history_reload()
{
  history -a
  history -c
  history -r
}

function bash_export()
{
  local __bashrc_path=${BASH_SOURCE[0]}

  if [ -r $__bashrc_path ]; then
    echo "# $(basename $__bashrc_path)"
    echo
    cat $__bashrc_path
    echo
  fi
  if [ -d $HOME/.bash.d ]; then
    local __script
    for __script in $HOME/.bash.d/*; do
      if [ -r $__script ]; then
        echo
        echo "# .bash.d/$(basename $__script)"
        echo
        cat $__script
        echo
      fi
    done
  fi
}

function bash_export_zip()
(
  _arg_assert_exists $1 "usage: bash_export_zip <path>" || return

  local __zip_output=$(realpath $1)
  local __to_zip

  cd $HOME || return

  for __script in .bashrc .bash_login .bash_logout .bash_profile .bash_aliases; do
    if [ -r "$__script" ]; then
      __to_zip="$__to_zip $__script"
    fi
  done

  zip -r $__zip_output $__to_zip .bash.d
  explorer $(dirname $__zip_output)
)

is_shell_interactive() { [[ $- == *i* ]]; }
is_shell_login() { shopt -q login_shell; }
is_shell_vscode() { [[ "$TERM_PROGRAM" == "vscode" ]]; }
is_shell_stdin_piped() { [ ! -t 0 ]; }
is_shell_stdout_piped() { [ ! -t 1 ]; }

is_empty() { [ -z "$1" ]; }
file_exists() { [ -f "$1" ]; }
file_not_empty() { [ -s "$1" ]; }
file_owned() { [ -O "$1" ]; }
file_suid() { [ -u "$1" ]; }
file_readable() { [ -r "$1" ]; }
file_writable() { [ -w "$1" ]; }
file_executable() { [ -x "$1" ]; }
dir_exists() { [ -d "$1" ]; }
bin_exists() { command -v $1 &> /dev/null; }

# print_err hello world
print_err()
{
  echo $@ >&2;
}

#
# Args
#

arg_exists()
{
  [ -n "$1" ]
}

arg_is_number()
{
  local __regex='^[+-]?[0-9]+$'
  [[ $1 =~ $__regex ]]
}

arg_is_float()
{
  local __regex='^[+-]?[0-9]+([.][0-9]+)$'
  [[ $1 =~ $__regex ]]
}

arg_is_negative()
{
  local __regex='^[-]'
  [[ $1 =~ $__regex ]]
}

arg_type()
{
  if arg_is_number $1; then
    echo "int"
  elif arg_is_float $1; then
    echo "float"
  elif arg_exists $1; then
    echo "string"
  else
    echo "null"
  fi
}

# _arg_assert_XXXXX "$arg" ERROR MESSAGE || return

_arg_assert_exists()
{
  if ! arg_exists $1; then
    shift
    print_err "$@"
    return 1
  fi
  return 0
}

_arg_assert_float()
{
  if ! arg_exists $1 || ! arg_is_float $1; then
    shift
    print_err "$@"
    return 1
  fi
  return 0
}

_arg_assert_number()
{
  if ! arg_exists $1 || ! arg_is_number $1; then
    shift
    print_err "$@"
    return 1
  fi
  return 0
}

_arg_assert_file()
{
  if ! arg_exists $1 || ! file_exists $1; then
    shift
    print_err "$@"
    return 1
  fi
  return 0
}

_arg_assert_binary()
{
  if ! arg_exists $1 || ! bin_exists $1; then
    shift
    print_err "$@"
    return 1
  fi
  return 0
}

#
# Option parsing
#
# Declarative argument parser with automatic -h help.
# Sets opt_* variables as locals in the caller scope (cascade-safe).
#
# Usage:
#   my_func() {
#     opt_begin "my_func [-v] [-n count] <file>"
#     opt_desc  "Process a file with options"
#     opt_flag  v verbose   "Enable verbose output"
#     opt_param n count 10  "Number of items"
#     opt_parse "$@" || return
#
#     # Variables set by opt_parse (local to the caller):
#     #   opt_verbose  - "true" or "false"
#     #   opt_count    - value or "10" (default)
#     #   opt_args     - array of remaining positional arguments
#     #   opt_usage    - the usage string (for later error messages)
#
#     local file="${opt_args[0]}"
#     _arg_assert_exists "$file" "$opt_usage" || return
#   }
#
# Cascading / nesting:
#   opt_parse is an alias that expands to:
#     eval "$__opt_locals"; _opt_parse
#   The eval declares all opt_* variables as local in the CALLER's scope
#   before _opt_parse writes to them.  This means nested calls are safe:
#   each function gets its own locals, and the outer function's values
#   are preserved after the inner one returns.
#
# Returns 0 on success (caller continues).
# Returns 1 on -h / error (caller does || return).

opt_begin()
{
  __opt_shorts=()
  __opt_longs=()
  __opt_types=()
  __opt_descs=()
  __opt_defaults=()
  __opt_desc_str=""
  _opt_usage_str="$1"
  __opt_locals="local opt_usage opt_args"
}

opt_desc() { __opt_desc_str="$1"; }

opt_flag()
{
  __opt_shorts+=("$1")
  __opt_longs+=("$2")
  __opt_types+=(b)
  __opt_defaults+=(false)
  __opt_descs+=("$3")
  __opt_locals+=" opt_$2"
}

opt_param()
{
  __opt_shorts+=("$1")
  __opt_longs+=("$2")
  __opt_types+=(p)
  __opt_defaults+=("$3")
  __opt_descs+=("$4")
  __opt_locals+=" opt_$2"
}

alias opt_parse='eval "$__opt_locals"; _opt_parse'

_opt_parse()
{
  local __i __n=${#__opt_shorts[@]}

  # build getopts string
  local __gs=":"
  for (( __i=0; __i<__n; __i++ )); do
    __gs+="${__opt_shorts[$__i]}"
    [[ "${__opt_types[$__i]}" == p ]] && __gs+=":"
  done
  __gs+="h"

  # set defaults directly
  for (( __i=0; __i<__n; __i++ )); do
    printf -v "opt_${__opt_longs[$__i]}" '%s' "${__opt_defaults[$__i]}"
  done
  opt_usage="$_opt_usage_str"

  # parse
  local OPTIND=1 __o
  while getopts "$__gs" __o "$@"; do
    case "$__o" in
      h)
        # build help on demand
        local __h="Usage: ${_opt_usage_str}"
        [[ -n "$__opt_desc_str" ]] && __h+=$'\n'"  ${__opt_desc_str}"$'\n'
        __h+=$'\n'"Options:"
        local __ln
        for (( __i=0; __i<__n; __i++ )); do
          if [[ "${__opt_types[$__i]}" == b ]]; then
            printf -v __ln "  -%-10s %s" "${__opt_shorts[$__i]}" "${__opt_descs[$__i]}"
          else
            printf -v __ln "  -%s %-8s %s" "${__opt_shorts[$__i]}" "<${__opt_longs[$__i]}>" "${__opt_descs[$__i]}"
            [[ -n "${__opt_defaults[$__i]}" ]] && __ln+=" (default: ${__opt_defaults[$__i]})"
          fi
          __h+=$'\n'"$__ln"
        done
        __h+=$'\n'"  -h          Show this help"
        echo "$__h"
        return 1
        ;;
      \?) print_err "Unknown option: -${OPTARG}"; return 1 ;;
      :)  print_err "Option -${OPTARG} requires a value"; return 1 ;;
      *)
        for (( __i=0; __i<__n; __i++ )); do
          if [[ "${__opt_shorts[$__i]}" == "$__o" ]]; then
            if [[ "${__opt_types[$__i]}" == b ]]; then
              printf -v "opt_${__opt_longs[$__i]}" '%s' "true"
            else
              printf -v "opt_${__opt_longs[$__i]}" '%s' "$OPTARG"
            fi
            break
          fi
        done
        ;;
    esac
  done
  shift $((OPTIND-1))

  # remaining positional args
  opt_args=("$@")
  return 0
}

#
# Variables
#

# var_exists PATH
var_exists()
{
  _arg_assert_exists "$1" "usage: var_exists <ENV_VAR>" || return

  local -n __var=$1
  arg_exists $__var
}

var_is_number()
{
  _arg_assert_exists "$1" "usage: var_is_number <ENV_VAR>" || return

  local -n __var=$1
  arg_is_number $__var
}

var_is_float()
{
  _arg_assert_exists "$1" "usage: var_is_float <ENV_VAR>" || return

  local -n __var=$1
  arg_is_float $__var
}

var_is_negative()
{
  _arg_assert_exists "$1" "usage: var_is_negative <ENV_VAR>" || return

  local -n __var=$1
  arg_is_negative $__var
}

var_is_array()
{
  local __res=$(declare -a | grep "$1=(")
  arg_exists $__res
}

var_is_dict()
{
  local __res=$(declare -A | grep "$1=(")
  arg_exists $__res
}

var_is_function()
{
  local __res=$(declare -f | grep "$1 ()")
  arg_exists $__res
}

var_type()
{
  _arg_assert_exists "$1" "usage: var_type <ENV_VAR>" || return

  if var_is_array $1; then
    echo "array"
    return
  elif var_is_dict $1; then
    echo "dict"
    return
  fi

  local -n __var=$1
  arg_type $__var
}

#
# Array
#

# create array: myArray=("cat" "dog" "mouse" "frog")

array_unpack()
{
  _arg_assert_exists "$1" "usage: array_unpack <ENV_VAR>" || return

  local -n __arr=$1
  echo ${__arr[@]}
}

array_len()
{
  _arg_assert_exists "$1" "usage: array_len <ENV_VAR>" || return

  local -n __arr=$1
  echo ${#__arr[@]}
}

array_print()
{
  _arg_assert_exists "$1" "usage: array_print <ENV_VAR>" || return

  local -n __arr=$1

  echo -n "["
  for i in ${!__arr[@]}
  do
    local __element=${__arr[${i}]}

    if [[ "${i}" != "0" ]]; then echo -n ", "; fi

    if var_is_number __element; then
      echo -n "${__element}"
    else
      echo -n "\"${__element}\""
    fi
  done
  unset i
  echo "]"
}

# array_loop ARRAY_VARIABLE COMMAND (%s gives current element)
array_loop()
{
  _arg_assert_exists "$1" "usage: array_loop <ENV_VAR_ARRAY> cmd (%s is current list element)" || return
  _arg_assert_exists "$2" "usage: array_loop <ENV_VAR_ARRAY> cmd (%s is current list element)" || return

  # get reference of array
  local -n __arr=$1
  shift
  sh_loop "${__arr[@]}" "$@"
}

#
# Dictionnary
#

# declare -A myDict=([a]=b [c]=d)

dict_get()
{
  _arg_assert_exists "$1" "usage: dict_get <ENV_VAR> <key>" || return
  _arg_assert_exists "$2" "usage: dict_get <ENV_VAR> <key>" || return

  local -n __dict=$1
  echo ${__dict[$2]}
}

dict_items()
{
  _arg_assert_exists "$1" "usage: dict_items <ENV_VAR>" || return

  local -n __dict=$1
  for __key in ${!__dict[@]}; do
      echo ${__key} ${__dict[${__key}]}
  done
  unset __key
}

dict_print()
{
  _arg_assert_exists "$1" "usage: dict_print <ENV_VAR>" || return

  local -n __dict=$1
  echo "{"
  for __key in ${!__dict[@]}; do
    local __value=${__dict[${__key}]}

    if var_is_number __key; then
      echo -n "  ${__key}: "
    else
      echo -n "  \"${__key}\": "
    fi

    if var_is_number __value; then
      echo "${__value},"
    else
      echo "\"${__value}\","
    fi
  done
  unset __key
  echo "}"
}

#
# Core
#

alias bash_reload='source $HOME/.bashrc'
alias sh_reload='bash_reload'

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
  open_explorer $(dirname $__zip_output)
)

is_shell_interactive() { [[ $- == *i* ]]; }
is_shell_login() { shopt -q login_shell; }
is_shell_vscode() { [[ "$TERM_PROGRAM" == "vscode" ]]; }
is_shell_piped() { [ ! -t 1 ]; }

is_linux() { [[ "$(uname)" == 'Linux' ]]; }
is_osx() { [[ "$(uname)" == 'Darwin' ]]; }
is_wsl() { [[ $(grep -i Microsoft /proc/version) ]]; }

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

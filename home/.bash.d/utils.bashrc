#
# Utils
#

alias search="grep -Hr --exclude-dir=.git --exclude-dir=build --exclude-dir=.vcpkg"
alias searchi="search -i"
# use keychron keyboards Fkeys
alias keychron_fkeys_on="echo 0 | sudo tee /sys/module/hid_apple/parameters/fnmode"
alias keychron_fkeys_off="echo 1 | sudo tee /sys/module/hid_apple/parameters/fnmode"
# copy with a progress bar
alias cpv='rsync -ah --info=progress2'
alias nowtime='date +"%T"'
alias nowdate='date +"%d-%m-%Y"'

# generate a random strong password
function passwd_gen() {
  strings /dev/urandom | grep -o '[[:alnum:]]' | head -n ${1:-30} | tr -d '\n'; echo
}

function hist_execute()
{
  `gum filter --placeholder 'Select to execute...' --indicator=">" < $HISTFILE --height 40`
}

function session_type()
{
  loginctl show-session $(loginctl | grep $(id -un) | awk '{print $1}') -p Type
}

clip_copy()
{
  if bin_exists xclip; then
    xclip -i -selection clipboard
  elif is_wsl ; then
    clip.exe
  elif bin_exists pbcopy; then
    pbcopy
  elif [ -w "/dev/clipboard" ]; then
    tee /dev/clipboard
  fi
}

clip_paste()
{
  if bin_exists xclip; then
    xclip -selection clipboard -o
  elif is_wsl ; then
    powershell.exe Get-Clipboard
  elif bin_exists pbpaste; then
    pbpaste
  elif [ -r "/dev/clipboard" ]; then
    cat /dev/clipboard
  fi
}

open_explorer()
{
  if is_wsl; then
    (cd $1 && explorer.exe .)
  elif bin_exists xdg-open; then
    xdg-open $1
  fi
}

#
# Filesystem
#

c()
{
  cd $1 && ls
}

up()
{
  local __dir=""
  local __limit=$1

  for ((i=1 ; i <= __limit ; i++))
  do
      __dir=$__dir/..
  done
  unset i

  __dir=$(echo $__dir | sed 's/^\///')

  if [ -z "$__dir" ]; then
    __dir=..
  fi

  cd $__dir
}

alias ..="cd .."
alias find_swp='find . -name "*.swp"'
alias rm_swp='find_swp | xargs -r rm'
# creates a temp dir and cds into it
alias cd_tmp='cd $(mktemp -d)'
# text files diff stripped of carriage return checking (windows/linux)
alias diff_text="diff --color --text --strip-trailing-cr"
alias tdiff="diff_text"
# unified (lines of context) diff
alias diff_unified="diff_text --unified=3"
alias udiff="diff_unified"
# side by side diff
alias diff_side="diff_text --side-by-side"
alias sdiff="diff_side"
# no common lines
alias diff_no_common="diff_text --suppress-common-lines"
alias ldiff="diff_no_common"

findf()
{
  find ${2:-.} -maxdepth 20 -type f -name "*$1*"
}

findd()
{
  find ${2:-.} -maxdepth 20 -type d -name "*$1*"
}

file_contained_in()
{
  # file_contained_in subfile.txt bigfile.txt
  _arg_assert_exists "$1" "usage: file_contained_in <file-contained> <file-containing>" || return
  _arg_assert_exists "$2" "usage: file_contained_in <file-contained> <file-containing>" || return

  local __res=`comm -23 <(sort $1) <(sort $2)`
  ! var_exists res
}

replace_all()
{
  _arg_assert_exists "$1" "usage: replace_all <from> <to>" || return
  _arg_assert_exists "$2" "usage: replace_all <from> <to>" || return

  # show list of changes with colors
  grep -R --exclude-dir=.git $1
  ask_confirm "Replacing '$1' -> '$2'" || return

  local __list_of_files=$(grep -Rl --exclude-dir=.git $1)

  echo "Will execute: sed -i 's/$1/$2/g' $__list_of_files"
  ask_confirm "Execute ?" || return

  sed -i "s/$1/$2/g" $__list_of_files
}

#
# Fun
#

alias busy="cat /dev/urandom | hexdump -C | grep 'ca fe'"

sh_cmd_most_used()
{
  local __count=$1

  if [ -z "$__count" ]; then __count=10; fi

  # list most used commands in bash
  history \
    | awk '{CMD[$2]++; count++;} END { for (a in CMD) print CMD[a] " " CMD[a] / count * 100 "% " a;}' \
    | grep -v "./" \
    | column -c3 -s " " -t \
    | sort -nr \
    | nl \
    | head -n$__count
}

#
# Print utilities
#

# cat file.log | log_color
log_color()
{
  awk '{
      if (tolower($0) ~ /debug/)
          {print "\033[36m" $0 "\033[39m"}
      else if (tolower($0) ~ /info/)
          {print "\033[32m" $0 "\033[39m"}
      else if (tolower($0) ~ /warn/)
          {print "\033[33m" $0 "\033[39m"}
      else if (tolower($0) ~ /err/)
          {print "\033[31m" $0 "\033[39m"}
      else
          {print $0}
  }'
}

# cmd | print_col 1
print_col()
{
  _arg_assert_number "$1" "usage: print_col <number>" || return

  awk "{print \$${1}}";
}

# cat file.csv | print_col_delim 1 ,
print_col_delim()
{
  _arg_assert_number "$1" "usage: print_col_delim <number>" || return
  _arg_assert_exists "$2" "usage: print_col_delim <number> <delimiter>" || return

  awk -F ${2} "{print \$${1}}";
}

# cmd | print_line 1
print_line()
{
  _arg_assert_number "$1" "usage: print_line <number>" || return

  sed -n ${1}p;
}

#
# Control utilities
#

ask_confirm() {
  local __confirm_msg="$@"
  if [ -z "$__confirm_msg" ]; then
    __confirm_msg="Confirm"
  fi

  if bin_exists gum; then
    gum confirm --default=no "$__confirm_msg"
    return
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

#
# Bash utilities
#

sh_range()
{
  _arg_assert_exists "$1" "usage: sh_range <number> cmd (%i is current number) ..." || return
  _arg_assert_exists "$2" "usage: sh_range <number> cmd (%i is current number) ..." || return

  local __range_end=$1
  shift
  local __command="$@"
  for i in $(seq 1 $__range_end)
  do
    $(printf "$__command\n" $i)
  done
  unset i
}

sh_loop()
{
  _arg_assert_exists "$1" "usage: sh_loop <arg list...> cmd (%s is current arg) ..." || return
  _arg_assert_exists "$2" "usage: sh_loop <arg list...> cmd (%s is current arg) ..." || return

  local __args="$1"
  shift
  local __command="$@"
  local __arg
  for __arg in $__args; do
    $(printf "$__command\n" $__arg)
  done
}

sh_timeout()
{
  _arg_assert_number "$1" "usage: sh_timeout <time> cmd..." || return
  _arg_assert_exists "$2" "usage: sh_timeout <time> cmd..." || return

  local __seconds="${1}"
  shift

  timeout --preserve-status $__seconds $@
}

alias sh_watch="watch --color --no-rerun --interval=2"
alias sh_watch_diff="sh_watch --differences"
alias sh_watch_until_different="sh_watch --chgexit"
alias sh_watch_until_err="sh_watch --errexit"

sh_watch_until_different_timeout()
{
  _arg_assert_number "$1" "usage: sh_watch_until_different_timeout <max cycles> cmd..." || return
  _arg_assert_exists "$2" "usage: sh_watch_until_different_timeout <max cycles> cmd..." || return

  local __cycles=${1}
  shift

  sh_watch --equexit=$__cycles $@
}

extract()
{
  if [ -f $1 ] ; then
    case $1 in
          *.tar.bz2)   tar xvjf $1    ;;
          *.tar.gz)    tar xvzf $1    ;;
          *.bz2)       bunzip2 $1     ;;
          *.rar)       unrar x $1     ;;
          *.gz)        gunzip $1      ;;
          *.tar)       tar xvf $1     ;;
          *.tbz2)      tar xvjf $1    ;;
          *.tgz)       tar xvzf $1    ;;
          *.zip)       unzip $1       ;;
          *.Z)         uncompress $1  ;;
          *.7z)        7z x $1        ;;
          *)           >&2 echo "don't know how to extract '$1'..." ;;
    esac
  else
    >&2 echo "'$1' is not a valid file!"
  fi
}

#
# File types utils
#

# csv_merge output.csv *.csv
csv_merge()
{
  _arg_assert_exists "$1" "usage: csv_merge <csv-merged-output> <csv-file_1> ..." || return
  _arg_assert_exists "$2" "usage: csv_merge <csv-merged-output> <csv-file_1> ..." || return

  local __output=$1
  shift
  awk '(NR == 1) || (FNR > 1)' "$@" > $__output
}

# csv_print file.csv ,
csv_print()
{
  _arg_assert_exists "$1" "usage: csv_print <csv-file> <delimiter>" || return
  _arg_assert_exists "$2" "usage: csv_print <csv-file> <delimiter>" || return

  cat $1 | column -t -s $2
}

csv_print_col()
{
  _arg_assert_exists "$1" "usage: csv_print_col <csv-file> <delimiter> <col_number>" || return
  _arg_assert_exists "$2" "usage: csv_print_col <csv-file> <delimiter> <col_number>" || return
  _arg_assert_number "$3" "usage: csv_print_col <csv-file> <delimiter> <col_number>" || return

  cat $1 | awk -F "$2" "{print \$$3}"
}

# csv_read file.csv ,
csv_read()
{
  _arg_assert_exists "$1" "usage: csv_read <csv-file> <delimiter>" || return
  _arg_assert_exists "$2" "usage: csv_read <csv-file> <delimiter>" || return

  csv_print $1 $2 | less -S
}

ini_get()
{
  _arg_assert_exists "$1" "usage: ini_get <ini-file> <section> <key>" || return
  _arg_assert_exists "$2" "usage: ini_get <ini-file> <section> <key>" || return
  _arg_assert_exists "$3" "usage: ini_get <ini-file> <section> <key>" || return

  local __file=$1
  local __section=$2
  local __key=$3

  awk '/^\[.*\]$/{obj=$0}/=/{print obj $0}' ${__file} \
      | grep '^\['${__section}'\]'${__key}'=' \
      | perl -pe 's/.*=//' \
      | tail -n 1
}
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
  eval "$(tail -n 40 $HISTFILE | gum filter --placeholder 'Select to execute...' --indicator=">")"
}

function session_type()
{
  loginctl show-session "$(loginctl | grep "$(id -un)" | awk '{print $1}')" -p Type
}

clip_copy()
{
  if is_x11; then
    # pkg: xclip
    if is_shell_stdin_piped; then
      xclip -i -selection clipboard
    else
      xclip -i -selection clipboard <<< "$1"
    fi
  elif is_wayland; then
    # pkg: wl-clipboard
    if is_shell_stdin_piped; then
      wl-copy
    else
      wl-copy <<< "$1"
    fi
  elif is_wsl; then
    if is_shell_stdin_piped; then
      clip.exe
    else
      clip.exe <<< "$1"
    fi
  elif bin_exists pbcopy; then
    if is_shell_stdin_piped; then
      pbcopy
    else
      pbcopy <<< "$1"
    fi
  elif [ -w "/dev/clipboard" ]; then
    if is_shell_stdin_piped; then
      tee /dev/clipboard
    else
      echo "$1" > /dev/clipboard
    fi
  elif bin_exists termux-clipboard-set; then
    if is_shell_stdin_piped; then
      termux-clipboard-set
    else
      termux-clipboard-set "$1"
    fi
  fi
}

clip_paste()
{
  if is_x11; then
    xclip -selection clipboard -o
  elif is_wayland; then
    wl-paste
  elif is_wsl; then
    powershell.exe Get-Clipboard
  elif bin_exists pbpaste; then
    pbpaste
  elif [ -r "/dev/clipboard" ]; then
    cat /dev/clipboard
  elif bin_exists termux-clipboard-get; then
    termux-clipboard-get
  fi
}

explorer()
{
  local path="${1:-.}"

  if is_wsl; then
    if [ -d "${path}" ]; then
      (cd "${path}" && explorer.exe .)
      # explorer.exe always return false
      true
    fi
  elif bin_exists xdg-open; then
    xdg-open "${path}"
  fi
}

from_hex()
{
  xxd --revert --plain
}

to_hex()
{
  xxd --plain
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
  _arg_assert_exists "$1" "usage: findf <search> [<path>]" || return
  find "${2:-.}" -maxdepth 20 -type f -name "*$1*"
}

findd()
{
  _arg_assert_exists "$1" "usage: findd <search> [<path>]" || return
  find "${2:-.}" -maxdepth 20 -type d -name "*$1*"
}

file_contained_in()
{
  _arg_assert_exists "$1" "usage: file_contained_in <file-contained> <file-containing>" || return
  _arg_assert_exists "$2" "usage: file_contained_in <file-contained> <file-containing>" || return

  local __res=$(comm -23 <(sort "$1") <(sort "$2"))
  [ -z "$__res" ]
}

replace_all()
{
  opt_begin "replace_all [-y] [-i] <from> <to>"
  opt_desc  "Replace all occurrences of a string in files recursively"
  opt_flag  y yes         "Skip confirmations"
  opt_flag  i insensitive "Case insensitive search"
  opt_parse "$@" || return

  local __from="${opt_args[0]}"
  local __to="${opt_args[1]}"
  _arg_assert_exists "$__from" "$opt_usage" || return
  _arg_assert_exists "$__to" "$opt_usage" || return

  local __grep_opts=""
  [ "$opt_insensitive" = "true" ] && __grep_opts="-i"

  # show list of changes with colors
  grep -R $__grep_opts --exclude-dir=.git "$__from"

  if [ "$opt_yes" != "true" ]; then
    ask_confirm "Replacing '$__from' -> '$__to'" || return
  fi

  local __list_of_files=$(grep -Rl $__grep_opts --exclude-dir=.git "$__from")

  local __sed_flags=""
  [ "$opt_insensitive" = "true" ] && __sed_flags="I"

  echo "Will execute: sed -i 's/$__from/$__to/g$__sed_flags' on $(echo "$__list_of_files" | wc -l) files"
  if [ "$opt_yes" != "true" ]; then
    ask_confirm "Execute ?" || return
  fi

  sed -i "s/$__from/$__to/g$__sed_flags" $__list_of_files
}

#
# Fun
#

alias busy="cat /dev/urandom | hexdump -C | grep 'ca fe'"

sh_cmd_most_used()
{
  opt_begin "sh_cmd_most_used [-n count]"
  opt_desc  "Show most used commands from bash history"
  opt_param n count 10 "Number of commands to show"
  opt_parse "$@" || return

  # list most used commands in bash
  history \
    | awk '{CMD[$2]++; count++;} END { for (a in CMD) print CMD[a] " " CMD[a] / count * 100 "% " a;}' \
    | grep -v "./" \
    | column -c3 -s " " -t \
    | sort -nr \
    | nl \
    | head -n${opt_count}
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
  opt_begin "extract [-d dir] [-l] <file>"
  opt_desc  "Extract archive files"
  opt_param d dir  "" "Output directory"
  opt_flag  l list    "List contents only, don't extract"
  opt_parse "$@" || return

  local __file="${opt_args[0]}"
  _arg_assert_file "$__file" "$opt_usage" || return

  if [[ "$opt_list" == "true" ]]; then
    case "$__file" in
      *.tar.bz2|*.tar.gz|*.tar|*.tbz2|*.tgz) tar tf "$__file" ;;
      *.zip) unzip -l "$__file" ;;
      *.rar) unrar l "$__file" ;;
      *.7z)  7z l "$__file" ;;
      *)     >&2 echo "don't know how to list '$__file'..." ;;
    esac
    return
  fi

  local __dest="${opt_dir:+$opt_dir/}"
  if [[ -n "$opt_dir" ]]; then
    mkdir -p "$opt_dir"
  fi

  case "$__file" in
    *.tar.bz2)   tar xvjf "$__file" ${opt_dir:+-C "$opt_dir"}  ;;
    *.tar.gz)    tar xvzf "$__file" ${opt_dir:+-C "$opt_dir"}  ;;
    *.bz2)       bunzip2 "$__file"     ;;
    *.rar)       unrar x "$__file" ${__dest}  ;;
    *.gz)        gunzip "$__file"      ;;
    *.tar)       tar xvf "$__file" ${opt_dir:+-C "$opt_dir"}   ;;
    *.tbz2)      tar xvjf "$__file" ${opt_dir:+-C "$opt_dir"}  ;;
    *.tgz)       tar xvzf "$__file" ${opt_dir:+-C "$opt_dir"}  ;;
    *.zip)       unzip "$__file" ${opt_dir:+-d "$opt_dir"}     ;;
    *.Z)         uncompress "$__file"  ;;
    *.7z)        7z x "$__file" ${opt_dir:+-o"$opt_dir"}       ;;
    *)           >&2 echo "don't know how to extract '$__file'..." ;;
  esac
}

#
# File types utils
#

csv_merge()
{
  _arg_assert_exists "$1" "usage: csv_merge <csv-merged-output> <csv-file_1> ..." || return
  _arg_assert_exists "$2" "usage: csv_merge <csv-merged-output> <csv-file_1> ..." || return

  local __output=$1
  shift
  awk '(NR == 1) || (FNR > 1)' "$@" > $__output
}

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

#
# Strings utils
#

str_contains()
{
  [[ "$1" == *"$2"* ]];
}

str_starts_with()
{
  [[ "$1" == "$2"* ]];
}

str_ends_with()
{
  [[ "$1" == *"$2" ]];
}

strsub()
{
  _arg_assert_exists "$1" "usage: strsub <string> <start> <length>" || return
  _arg_assert_number "$2" "usage: strsub <string> <start> <length>" || return
  _arg_assert_number "$3" "usage: strsub <string> <start> <length>" || return

  echo "${1:$2:$3}"
}

strlen()
{
  _arg_assert_exists "$1" "usage: strlen <string>" || return

  echo "${#1}"
}

str_upper()
{
  _arg_assert_exists "$1" "usage: str_upper <string>" || return

  echo "${1^^}"
}

str_lower()
{
  _arg_assert_exists "$1" "usage: str_lower <string>" || return

  echo "${1,,}"
}

str_replace()
{
  _arg_assert_exists "$1" "usage: str_replace <string> <search> <replace>" || return
  _arg_assert_exists "$2" "usage: str_replace <string> <search> <replace>" || return
  _arg_assert_exists "$3" "usage: str_replace <string> <search> <replace>" || return

  echo "${1//$2/$3}"
}

str_trim_left()
{
  _arg_assert_exists "$1" "usage: str_trim_left <string>" || return

  echo "${1#"${1%%[![:space:]]*}"}"
}

str_trim_right()
{
  _arg_assert_exists "$1" "usage: str_trim_right <string>" || return

  echo "${1%"${1##*[![:space:]]}"}"
}

str_trim()
{
  _arg_assert_exists "$1" "usage: str_trim <string>" || return

  local trimmed_left=$(str_trim_left "$1")
  str_trim_right "$trimmed_left"
}

# Sh utils

sh_path_find()
{
  _arg_assert_exists "$1" "usage: sh_path_find <command>" || return

  IFS=':' read -ra SUBPATH <<< "$PATH"
  local dir
  for dir in "${SUBPATH[@]}"; do
    if [ -f "$dir/$1" ]; then
      echo "$dir/$1"
    fi
  done
}

sh_path_add()
{
  _arg_assert_exists "$1" "usage: sh_path_add <path-to-add> [<path-to-add>...]" || return

  local p
  for p in "$@"; do
    [ -z "$p" ] && continue

    if [ ! -d "$p" ]; then
      echo "sh_path_add: '$p' is not a directory" >&2
      continue
    fi

    if ! str_contains "$PATH" "$p"; then
      export PATH="${PATH}:$p"
    fi
  done
}
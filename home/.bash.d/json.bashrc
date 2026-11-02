#!/bin/bash
#
# JSON / jq utilities
#

# json_pp — pretty-print JSON from stdin with colors
#   curl -s api.example.com | json_pp
json_pp()
{
  _arg_assert_binary jq "jq is required" || return
  jq -C '.' 2>/dev/null || { print_err "invalid JSON"; return 1; }
}

# json_compact — minify JSON from stdin (single line)
#   cat data.json | json_compact
json_compact()
{
  _arg_assert_binary jq "jq is required" || return
  jq -c '.' 2>/dev/null || { print_err "invalid JSON"; return 1; }
}

# json_get <jq-filter> — extract a raw value from piped JSON
#   curl -s api.example.com/user | json_get .name
#   cat data.json | json_get '.[0].title'
json_get()
{
  _arg_assert_binary jq "jq is required" || return
  _arg_assert_exists "$1" "usage: json_get <jq-filter>" || return
  jq -r "$1" 2>/dev/null
}

# json_keys [jq-filter] — list keys of a JSON object (default: root)
#   cat data.json | json_keys
#   cat data.json | json_keys .metadata
json_keys()
{
  _arg_assert_binary jq "jq is required" || return
  jq -r "${1:-.} | keys[]" 2>/dev/null
}

# json_paths — list all leaf paths in a JSON document
#   cat data.json | json_paths
json_paths()
{
  _arg_assert_binary jq "jq is required" || return
  jq -r 'paths(scalars) | join(".")' 2>/dev/null
}

# json_type <jq-filter> — return the jq type at a given path
#   echo '{"a":42,"b":"hi"}' | json_type .a   # number
#   echo '{"a":42}' | json_type .              # object
json_type()
{
  _arg_assert_binary jq "jq is required" || return
  _arg_assert_exists "$1" "usage: json_type <jq-filter>" || return
  jq -r "$1 | type" 2>/dev/null
}

# is_json [string] — returns 0 if stdin (or first arg) is valid JSON
#   echo '{"valid":true}' | is_json && echo "ok"
#   is_json '{"valid":true}' && echo "ok"
is_json()
{
  _arg_assert_binary jq "jq is required" || return
  if is_shell_stdin_piped; then
    jq empty 2>/dev/null
  elif arg_exists "$1"; then
    echo "$1" | jq empty 2>/dev/null
  else
    return 1
  fi
}

# json_validate — validate JSON from stdin and print any parse error
#   cat maybe_broken.json | json_validate
json_validate()
{
  _arg_assert_binary jq "jq is required" || return
  jq empty 2>&1
}

# json_table — render an array of objects as an aligned table
#   curl -s api.example.com/users | json_table
json_table()
{
  _arg_assert_binary jq "jq is required" || return

  local __input
  __input=$(cat)
  local __first
  __first=$(echo "$__input" | jq -r 'if type=="array" then (.[0] | keys) else keys end | @tsv' 2>/dev/null) \
    || { print_err "not a JSON array of objects"; return 1; }

  { echo "$__first"; echo "$__input" | jq -r '(.[0] | keys) as $cols | .[] | [.[$cols[]]] | @tsv' 2>/dev/null; } | column -t -s $'\t'
}

# json_array — convert stdin lines to a JSON array
#   ls | json_array
json_array()
{
  _arg_assert_binary jq "jq is required" || return
  jq -R -s 'split("\n") | map(select(length > 0))' 2>/dev/null
}

# json_diff <file1> <file2> — structural JSON diff (key-sorted)
#   json_diff before.json after.json
json_diff()
{
  _arg_assert_binary jq "jq is required" || return
  _arg_assert_file "$1" "usage: json_diff <file1> <file2>" || return
  _arg_assert_file "$2" "usage: json_diff <file1> <file2>" || return
  diff -u <(jq -S '.' "$1") <(jq -S '.' "$2")
}

# json_pick <field...> — select specific fields from piped JSON (array or object)
#   cat data.json | json_pick .name .url
json_pick()
{
  _arg_assert_binary jq "jq is required" || return
  _arg_assert_exists "$1" "usage: json_pick <field...>" || return

  local __filter="{"
  local __first=true
  local __f
  local __key
  for __f in "$@"; do
    $__first && __first=false || __filter+=", "
    __key="${__f#.}"
    __filter+="$__key"
  done
  __filter+="}"
  jq "$__filter" 2>/dev/null
}

# json_count — count elements (array length, object key count, or 1)
#   echo '[1,2,3]' | json_count   # 3
json_count()
{
  _arg_assert_binary jq "jq is required" || return
  jq 'if type=="array" then length elif type=="object" then keys|length else 1 end' 2>/dev/null
}

# json_first — first element of a JSON array
#   echo '[10,20,30]' | json_first   # 10
json_first()
{
  _arg_assert_binary jq "jq is required" || return
  jq '.[0]' 2>/dev/null
}

# json_last — last element of a JSON array
#   echo '[10,20,30]' | json_last   # 30
json_last()
{
  _arg_assert_binary jq "jq is required" || return
  jq '.[-1]' 2>/dev/null
}

# json_sort <field> — sort a JSON array of objects by a field
#   cat data.json | json_sort .name
json_sort()
{
  _arg_assert_binary jq "jq is required" || return
  _arg_assert_exists "$1" "usage: json_sort <field>" || return
  jq "sort_by($1)" 2>/dev/null
}

# json_group <field> — group an array of objects by a field
#   cat data.json | json_group .category
json_group()
{
  _arg_assert_binary jq "jq is required" || return
  _arg_assert_exists "$1" "usage: json_group <field>" || return
  jq "group_by($1)" 2>/dev/null
}

# json_to_csv — convert a JSON array of objects to CSV
#   cat data.json | json_to_csv
json_to_csv()
{
  _arg_assert_binary jq "jq is required" || return
  jq -r '(.[0] | keys) as $cols | $cols, (.[] | [.[$cols[]]]) | @csv' 2>/dev/null
}

# json_from_csv — convert CSV to a JSON array of objects
#   cat data.csv | json_from_csv
json_from_csv()
{
  _arg_assert_binary jq "jq is required" || return
  local __header
  read -r __header
  local __cols
  __cols=$(echo "$__header" | jq -R 'split(",") | map(gsub("^\\s+|\\s+$";""))' 2>/dev/null) \
    || { print_err "invalid CSV header"; return 1; }

  jq --slurp --raw-input \
    "split(\"\n\") | map(select(length > 0) | split(\",\")) | .[1:] \
     | map([.[] | gsub(\"^\\s+|\\s+$\";\"\")]) \
     | map($__cols as \$cols | reduce range(0; \$cols | length) as \$i ({}; .[\$cols[\$i]] = .[\$i]))" 2>/dev/null
}

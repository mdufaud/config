#!/usr/bin/env bash
set -euo pipefail

mode=${1:-}
arg=${2:-}

usage() {
  printf 'Usage: git-fs-stats.sh files|lines|ext|blobs [N] | dir [depth] | repo | all\n' >&2
  exit 2
}

[[ -z $arg || $arg =~ ^[0-9]+$ ]] || usage

hum='function hum(x, u, i) { split("B K M G T", u, " "); i = 1; while (x >= 1024 && i < 5) { x /= 1024; i++ } return (i == 1) ? sprintf("%d%s", x, u[i]) : sprintf("%.1f%s", x, u[i]) } '

data() {
  awk -F'\t' -v OFS='\t' '
    FILENAME == ARGV[1] { sub(/^HEAD:/, "", $1); lines[$1] = $2; next }
    { split($1, a, " "); if (a[2] == "blob") print a[4], lines[$2] + 0, $2 }
  ' <(git grep -I -z -c '' HEAD -- | tr '\0' '\t') <(git ls-tree -r -l -z HEAD | tr '\0' '\n')
}

mode_files() {
  local n=${1:-20}
  {
    printf 'SIZE\tLINES\tFILE\n'
    printf '%s\n' "$all" | sort -t$'\t' -k1,1nr | sed -n "1,${n}p" | awk -F'\t' -v OFS='\t' "$hum"'{ print hum($1), $2, $3 }'
  } | column -ts $'\t'
}

mode_lines() {
  local n=${1:-20}
  {
    printf 'LINES\tSIZE\tFILE\n'
    printf '%s\n' "$all" | sort -t$'\t' -k2,2nr | sed -n "1,${n}p" | awk -F'\t' -v OFS='\t' "$hum"'{ print $2, hum($1), $3 }'
    printf '%s\n' "$all" | awk -F'\t' -v OFS='\t' "$hum"'{ l += $2; s += $1; c++ } END { print l, hum(s), "TOTAL (" c " files)" }'
  } | column -ts $'\t'
}

mode_ext() {
  local n=${1:-15}
  {
    printf 'EXT\tFILES\tLINES\tSIZE\n'
    printf '%s\n' "$all" | awk -F'\t' '
      {
        b = $3; sub(/.*\//, "", b)
        i = match(b, /\.[^.]+$/)
        e = (i > 1) ? tolower(substr(b, i)) : "(none)"
        f[e]++; l[e] += $2; s[e] += $1
      }
      END { for (e in f) print s[e] "\t" e "\t" f[e] "\t" l[e] }
    ' | sort -t$'\t' -k1,1nr | sed -n "1,${n}p" | awk -F'\t' -v OFS='\t' "$hum"'{ print $2, $3, $4, hum($1) }'
  } | column -ts $'\t'
}

mode_dir() {
  local depth=${1:-1}
  local n=${2:-20}
  {
    printf 'DIR\tFILES\tLINES\tSIZE\n'
    printf '%s\n' "$all" | awk -F'\t' -v d="$depth" '
      {
        c = split($3, p, "/")
        k = (c - 1 < d) ? c - 1 : d
        dir = ""
        for (i = 1; i <= k; i++) dir = dir (i > 1 ? "/" : "") p[i]
        if (dir == "") dir = "."
        f[dir]++; l[dir] += $2; s[dir] += $1
      }
      END { for (dir in f) print s[dir] "\t" dir "\t" f[dir] "\t" l[dir] }
    ' | sort -t$'\t' -k1,1nr | sed -n "1,${n}p" | awk -F'\t' -v OFS='\t' "$hum"'{ print $2, $3, $4, hum($1) }'
  } | column -ts $'\t'
}

mode_blobs() {
  local n=${1:-20}
  {
    printf 'SIZE\tSHA\tPATH\n'
    git rev-list --objects --all |
      git cat-file --batch-check='%(objecttype) %(objectname) %(objectsize) %(rest)' |
      awk '$1 == "blob" { size = $3; sha = substr($2, 1, 10); path = $0; sub(/^[^ ]+ [^ ]+ [^ ]+ ?/, "", path); print size "\t" sha "\t" path }' |
      sort -t$'\t' -k1,1nr | sed -n "1,${n}p" | awk -F'\t' -v OFS='\t' "$hum"'{ print hum($1), $2, $3 }'
  } | column -ts $'\t'
}

mode_repo() {
  printf 'git dir: %s\n' "$(du -sh "$(git rev-parse --git-common-dir)" | cut -f1)"
  git count-objects -vH
}

mode_all() {
  printf '%s\n' "$all" | awk -F'\t' "$hum"'{ l += $2; s += $1; c++ } END { printf "%d files, %d lines, %s (HEAD tree)\n", c, l, hum(s) }'
  printf '\nBy extension\n'
  mode_ext 10
  printf '\nBy directory\n'
  mode_dir 1 10
  printf '\n'
  mode_repo
}

all=
case $mode in
  files|lines|ext|dir|all)
    all=$(data)
    [[ -n $all ]] || { printf 'No files in HEAD\n'; exit 0; }
    ;;
  blobs|repo) ;;
  *) usage ;;
esac

case $mode in
  files) mode_files "$arg" ;;
  lines) mode_lines "$arg" ;;
  ext) mode_ext "$arg" ;;
  dir) mode_dir "$arg" ;;
  blobs) mode_blobs "$arg" ;;
  repo) mode_repo ;;
  all) mode_all ;;
esac

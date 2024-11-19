#!/bin/bash

unset COLORTERM

# lf_ratios='1:2:3'
# one_ratio = width / total_ratio
# preview_ratio = 3
# preview_width = one_ratio * preview_ratio

__ratio="$(( (${lf_width} / 6) * 3 ))"

case "$1" in
    *.tar*) tar tf "$1";;
    *.zip) unzip -l "$1";;
    # *.rar) unrar l "$1";;
    # *.7z) 7z l "$1";;
    # *.pdf) pdftotext "$1" -;;
    *) /usr/bin/batcat --color always --wrap auto --terminal-width ${__ratio} "$@" ;;
esac
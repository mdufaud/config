#!/bin/bash

previewer="cat"
if command -v batcat; then
    unset COLORTERM
    previewer="batcat --color always"
fi

case "$1" in
    *.tar*) tar tf "$1";;
    *.zip*) unzip -l "$1";;
    *) $previewer "$@";;
esac
#!/bin/bash

update_into_from() {
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

    if [ -d $path_from ]; then
        for file in $(ls -A $path_from); do
            local update_path="$path_from/$file"

            if [ -f $update_path ]; then
                echo "Copying $update_path ---> $path_into/$file"
                cp $update_path $path_into/$file
            else
                echo $update_path is not a file !
            fi
        done
    elif [ -f $path_from ]; then
        echo "Copying $path_from ---> $path_into"
        cp $path_from $path_into
    fi
}

update_into_from home/.bashrc $HOME/.bashrc
update_into_from home/.bash.d $HOME/.bash.d
update_into_from home/.LS_COLORS $HOME/.LS_COLORS

update_into_from apt/.config/lf $HOME/.config/lf
update_into_from apt/.gitconfig $HOME/.gitconfig
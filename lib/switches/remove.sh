#!/bin/bash

if [[ -z "$1" ]]; then
    msg="Error: No script supplied."
    help
    exit 1
fi

target="$1"
if [ "${target,,}" == "pastebin" ]; then
    if [[ ! -d "$scripts_dir/pastebin" ]]; then
        echo "Pastebin folder does not exist."
        exit 1
    fi

    read -p "Clear ALL your pastebin scripts? This can't be undone. [(Y)es/(N)o] " c
    choice="${c,,}"
    case "$choice" in
        y)
            rm -rf "$scripts_dir/pastebin"

            if [[ -d "$scripts_dir/pastebin" ]]; then
                echo "Error occured while deleting the pastebin folder."
            else
                echo "Pastebin folder removed."
            fi
            exit 0
            ;;
        *)
            exit 0
            ;;
    esac
fi

if [[ ! -d "$scripts_dir/$1" ]]; then
    echo "Script does not exist."
    exit 1
fi

rm -rf "$scripts_dir/$target"
if [ -d "$scripts_dir/$target" ]; then
    echo "bpkg could not delete specified script."
    exit 1
fi

echo "Script \"$target\" removed."
exit 0

#!/bin/bash

list_bool="off"
list_method=

for m in "${valid_list_methods[@]}"; do
    if [ "$m" == "${1#-}" ]; then
        list_bool="yes"
        list_method="$m"
        break
    fi
done

if [ "$list_bool" != "yes" ]; then
    echo "Invalid list switch."
    exit 1
fi

if [ "$list_method" == "local" ]; then
    script_count=0
    echo "PASTEBIN folder is excluded."
    for dir in scripts/*/; do
        basename_dir="$(basename $dir)"
        if [[ -d "$dir" && "${basename_dir,,}" != "pastebin" ]]; then
            ((script_count++))
            echo "$script_count. $basename_dir"
        fi
    done

    if [ "$script_count" -eq 0 ]; then
        echo "You have no scripts."
        exit 1
    fi
else
    if [ -z "$2" ]; then
        echo "No get method supplied."
        exit 1
    fi

    for m in "${valid_methods[@]}"; do
        if [ "$m" == "${2#-use}" ]; then
            list_bool="yes"
            list_method="$m"
        fi
    done

    if [ "$list_bool" != "yes" ]; then
        echo "Invalid method."
        exit 1
    fi

    echo "Reading script list..."
    script_count=0
    format='%-4s %-20s %-45s %-15s\n'
    printf "$format" "No" "Name" "Description" "Author"
    printf '%0.s-' {1..100}; echo
    while IFS=',' read -r prefix name location desc filename hash author category last_modified tags script_size ; do
        if [[ "$prefix" == "[#]" ]]; then
            ((script_count++))
            trunc_name=$(trim "$(truncate "$name" 18)")
            trunc_desc=$(trim "$(truncate "$desc" 40)")
            trunc_author=$(trim "$(truncate "$author" 10)")
            printf "$format" "$script_count."  "$trunc_name" "$trunc_desc" "$trunc_author"
        fi
    done < "$master_file"

    if [ $script_count -eq 0 ]; then
        echo "Could not get the script list."
        exit 1
    fi
fi

exit 0

#!/bin/bash

get_bool=""
get_method=""

if [[ -z "$1" ]]; then
    echo "Error: No get method supplied."
    exit 1
fi

if [[ -z "$2" ]]; then
    echo "Error: No script name supplied."
    exit 1
fi

get_method="$1"
script_name="$2"
for m in "${valid_methods[@]}"; do
    if [[ "$m" == "${get_method#-use}" ]]; then
        get_bool="yes"
        get_method="$m"
    fi
done

if [ "$get_bool" != "yes" ]; then
    msg="Error: Invalid get method."
    help
    exit 1
fi

get_bool=""

echo "Reading script list..."
if [ ! -f "$master_file" ]; then
    echo "An error occured getting script list."
    exit 1
fi

script_count=0
while IFS=',' read -r prefix name location desc filename hash author category last_modified tags script_size ; do
    if [[ "$prefix" == "[#]" && "$name" == "$script_name" ]]; then
        target_dir="$scripts_dir/${name}"
        target_path="$target_dir/$filename"

        if [[ "$info_mode" == "on" ]]; then
            echo
            echo "Name: $name"
            echo "Author: $author"
            echo "Description: $desc"
            echo "Location: $location"
            echo "Hash: $hash"
            info_mode="off"
            exit 0
        fi

        if [[ -f "$target_dir" ]]; then
            echo "Script \"$name\" is already downloaded."
            exit 1
        fi

        ((script_count++))

        echo "Fetching $name..."

        if [[ ! -d "$target_dir" ]]; then
            mkdir "$target_dir"
        fi

        if ! download "$get_method" "$location" "$target_path"; then
            echo "An error occured while fetching script."
            exit 1
        fi

        if [ -f "$target_path" ]; then
            echo "$hash" > "$target_dir/hash"
            echo "$desc" > "$target_dir/info"
            echo "$author" > "$target_dir/author"
            echo "Done."
        fi
    fi
done < "$master_file"

if [ "$script_count" -eq 0 ]; then
    echo "Script \"$script_name\" does not exist on the server."
    echo "Try deleting $master_file if you are certain it exists..."
    exit 1
fi

exit 0

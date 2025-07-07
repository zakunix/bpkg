#!/bin/bash

update_bool=
update_method=
target="$2"

if [ -z "$1" ]; then
    echo "Error: No update method supplied."
    exit 1
fi

if [ -z "$target" ]; then
    echo "Error: No script name supplied."
    exit 1
fi

for m in "${valid_methods[@]}"; do
    if [ "$m" == "${1#-use}" ]; then
        update_bool="yes"
        update_method="$m"
    fi
done

if [ "$update_bool" != "yes" ]; then
    msg="Error: Invalid update method."
    help
    exit 1
fi

update_bool=
if [ ! -d "$scripts_dir/$target" ]; then
    echo "Error: Script \"$target\" does not exist."
    exit 1
fi

echo "Reading script list..."
if [ ! -f "$master_file" ]; then
    echo "An error occured getting script list."
    exit 1
fi

script_count=0
while IFS=',' read -r prefix name location desc filename hash author category last_modified tags script_size ; do
    ((script_count++))
    if [[ "$prefix" == "[#]" && "$name" == "$target" ]]; then
        echo "Checking to see if there's a new version for $name..."
        current_hash=
        if [ ! -f "$scripts_dir/$target/hash" ]; then
            echo "Hash file for $name is missing. Updating anyway."
        else
            current_hash=$(<"$scripts_dir/$target/hash")
            if [ "$current_hash" == "$hash" ]; then
                echo "This is already the latest version."
                exit 1
            fi
        fi

        temp_file_dir="$temp_dir/$name"
        temp_file_path="$temp_file_dir/$filename"
        if [ ! -d "$temp_file_dir" ]; then
            mkdir -p "$temp_file_dir"
        fi

        if ! download "$update_method" "$location" "$temp_file_path"; then
            echo "An error occured while fetching script."
            exit 1
        fi

        if [ ! -f "$temp_file_path" ]; then
            echo "An error occured while downloading the latest version of the script."
            exit 1
        fi

        if [ -z "$current_hash" ]; then
            $current_hash=$(date +%s%N | sha256sum | head -c 32)
        fi

        if [ ! -d "$scripts_dir/$name/old-$current_hash/" ]; then
            mkdir "$scripts_dir/$name/old-$current_hash/"
        fi

        echo "Cleaning up old version..."
        if [ -f "$scripts_dir/$name/$filename" ]; then
            mv -f "$scripts_dir/$name/$filename" "$scripts_dir/$name/old-$current_hash"
        fi

        mv -f "$temp_file_path" "$scripts_dir/$name/$filename"
        rm -rf "$temp_file_dir"
        if [ ! -f "$scripts_dir/$name/$filename" ]; then
            echo "An error occured while updating the script."
            exit 1
        fi

        echo "$hash" > "$scripts_dir/$name/hash"
        echo "$desc" > "$scripts_dir/$name/info"
        echo "$author" > "$scripts_dir/$name/author"
        echo Done.
    fi
done < "$master_file"

if [ "$script_count" -eq 0 ]; then
    echo "The script \"$target\" does not exist on the server."
    exit 1
fi

exit 0

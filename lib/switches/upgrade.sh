#!/bin/bash

upgrade_bool=""
ugrade_method=""

if [ -z "$1" ]; then
    echo "Error: No update method supplied."
    exit 1
fi

upgrade_method="$1"
for m in "${valid_methods[@]}"; do
    if [ "$m" == "${upgrade_method#-use}" ]; then
        upgrade_method="$m"
        upgrade_bool="yes"
        break
    fi
done

if [ "$upgrade_bool" != "yes" ]; then
    msg="Error: Invalid get method."
    help
    exit 1
fi

sess_rand=$(date +%s%N | sha256sum | head -c 32)
new_hash_temp_file="$temp_dir/hash-$sess_rand"
if ! download "$upgrade_method" "$upgrade_hash_location" "$new_hash_temp_file"; then
    echo "An error occured while fetching new hash."
    exit 1
fi

new_upgrade_hash=$(<"$new_hash_temp_file")
echo "$new_upgrade_hash"
if [ ! -f "$bin_dir/hash" ]; then
    echo "No local hash found. Will upgrade anyway."
    echo $(date +%s%N | sha256sum | head -c 32) > "$bin_dir/hash"
fi
rm -f "$new_hash_temp_file"

current_upgrade_hash=$(<"$bin_dir/hash")
if [ "$new_upgrade_hash" == "$current_upgrade_hash" ]; then
    echo "You already have the latest version."
    exit 1
fi

if [ -f "$upgrade_file" ]; then
    rm -f "$upgrade_file"
fi

if [ -f "$changelog_file" ]; then
    rm -f "$changelog_file"
fi

if [ -f "$temp_dir/bpkg.sh" ]; then
    rm -f "$temp_dir/bpkg.sh"
fi

if ! download "$upgrade_method" "$upgrade_script_location" "$temp_dir/upgrade.sh"; then
    echo "An error occured while fetching new upgrade.sh script."
    exit 1
fi

if ! download "$upgrade_method" "$bpkg_location" "$temp_dir/bpkg.sh"; then
    echo "An error occured while fetching new bpkg."
    exit 1
fi

if ! download "$upgrade_method" "$changelog_location" "$temp_dir/changelog"; then
    echo "An error occured while fetching new changelogs."
    exit 1
fi

isError=0
if [[ ! -f "$upgrade_file" ]]; then
    echo "Failed to get the bpkg upgrade script."
    isError=1
fi

if [[ ! -f "changelog" ]]; then
    echo "Failed to get the changelog."
    isError=1
fi

if [[ ! -f "$temp_dir/bpkg.sh" ]]; then
    echo "Failed to get bpkg latest version."
    isError=1
fi

if [ ! isError -eq 0 ]; then
    exit 1
fi

./"$upgrade_file" &

exit 0

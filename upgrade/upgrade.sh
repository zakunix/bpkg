#!/bin/bash

echo "Updating..."
sleep 5
mv -f $temp_dir/bpkg.sh ./bpkg.sh
mv -f $temp_dir/changelog ./changelog
echo \"$new_upgrade_hash\" > bin/hash
nano ./changelog
read -p ""

#!/bin/bash

source "$(dirname "$0")/lib/config.sh"
source "$(dirname "$0")/lib/functions.sh"
source "$switches_dir/switches.sh"

if [ ! -f "$master_file" ]; then
    download "sh" "$list_location" "$master_file"
fi
clear

detect_package_manager
if [ "$pkgmanager" == "unknown" ]; then
    echo "Distro is not supported."
    exit 1
fi

checkcurl

echo "------------------------------------------"
echo "${0#./} $version"
echo "Bash script manager"
echo "Made by Zakunix"
echo "------------------------------------------"
echo

if [ -z "$1" ]; then
    msg="Error: No switch supplied."
    help
    exit 1
fi

valid_bool="off"
switch="$1"
for m in "${valid_switches[@]}"; do
    if [[ "$m" == "${switch#-}" ]]; then
        switch="$m"
        valid_bool="on"
        break
    fi
done

if [[ "$valid_bool" == "off" ]]; then
    msg="Error: Invalid switch."
    help
    exit 1
fi

shift
"$switch" "${@}"
exit 0

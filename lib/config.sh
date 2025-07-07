#!/bin/bash

# The three below can be changed if you want to, but make sure you know what you're doing.
temp_dir="temp"
scripts_dir="scripts"
bin_dir="bin"
lib_dir="lib"

switches_dir="lib/switches"

# Everything below here SHOULD NOT be changed unless you DEFINITELY know what you're doing
master_file="$temp_dir/master"

info_mode="off"
list_location="https://raw.githubusercontent.com/zakunix/Linux-Scripts/refs/heads/main/master.txt"
pkgmanager="dnf"

msg=""

valid_switches=(help get pastebin remove update info list upgrade)
valid_methods=(js sh curl wget)
valid_list_methods=(local server)
# Major, Minor, Bugfixes/Patches
version="v2.2.0"

upgrade_file="upgrade.sh"
changelog_file="changelog"

upgrade_hash_location="https://raw.githubusercontent.com/zakunix/bpkg/refs/heads/main/bin/hash"
upgrade_script_location="https://raw.githubusercontent.com/zakunix/bpkg/refs/heads/main/upgrade/upgrade.sh"
bpkg_location="https://raw.githubusercontent.com/zakunix/bpkg/refs/heads/main/bpkg.sh"
changelog_location="https://raw.githubusercontent.com/zakunix/bpkg/refs/heads/main/changelog"

declare -A switch_descriptions=(
    [get]="Fetches the script using the specified method."
    [pastebin]="Gets a Pastebin script using the specified method."
    [remove]="Removes the script."
    [update]="Fetches the script using the specified method."
    [info]="Gets info on the specified script."
    [list]="Gets the list of scripts (server or local)."
    [upgrade]="Gets bpkg's latest version."
    [verifyself]="Verifies the core components of bpkg."
    [help]="Prints this help screen."
)

mkdir -p $temp_dir
mkdir -p $scripts_dir

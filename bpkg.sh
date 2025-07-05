#!/bin/bash

# The three below can be changed if you want to, but make sure you know what you're doing.
temp_dir="temp"
scripts_dir="scripts"
bin_dir="bin"

# Everything below here SHOULD NOT be changed unless you DEFINITELY know what you're doing
master_file="$temp_dir/master"

info_mode="off"
list_location="https://raw.githubusercontent.com/zakunix/Linux-Scripts/refs/heads/main/master.txt"
pkgmanager="dnf"

msg=""

valid_switches=(help get pastebin)
valid_methods=(js sh curl wget)
# Major, Minor, Bugfixes/Patches
version="v1.0.0"

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

detect_package_manager() {
  if command -v apt >/dev/null 2>&1; then
    pkgmanager="apt"
  elif command -v dnf >/dev/null 2>&1; then
    pkgmanager="dnf"
  elif command -v pacman >/dev/null 2>&1; then
    pkgmanager="pacman"
  elif command -v zypper >/dev/null 2>&1; then
    pkgmanager="zypper"
  else
    pkgmanager="unknown"
  fi
}

checkcurl() {
    if ! command -v curl >/dev/null 2>&1; then
        echo "Curl is not installed."
        read -p "Would you like to install curl now? [Y/N]: " choice
        choice=${choice,,}

        if [[ "$choice" != "y" && "$choice" != "yes" ]]; then
            echo "Skipped curl installation."
            exit 1
        fi

        pkgmanager=$(detect_package_manager)

        case "$pkgmanager" in
            apt)
                sudo apt update && sudo apt install -y curl
                ;;
            dnf)
                sudo dnf install -y curl
                ;;
            pacman)
                sudo pacman -Sy curl --noconfirm
                ;;
            zypper)
                sudo zypper install -y curl
                ;;
            *)
                echo "Unsupported package manager. Please install curl manually."
                exit 1
                ;;
        esac

        if command -v curl >/dev/null 2>&1; then
            echo "curl installed successfully."
            exit 0
        else
            echo "curl installation failed."
            exit 1
        fi
    fi
}

download() {
    local method="$1"
    local source="$2"
    local dest="$3"

    method="${method#-use}"

    case "$method" in
        curl)
            curl -fsSL "$source" -o "$dest" || return 1
            ;;
        wget)
            wget -q "$source" -O "$dest" || return 1
            ;;
        sh)
            if [ ! -f "./$bin_dir/download.sh" ]; then
                echo "Bash download method selected, but $bin_dir/download.sh not found."
                return 1
            fi

            ./"$bin_dir"/download.sh "$source" "$dest"
            if [ ! -f "$dest" ]; then
                echo "download.sh did not create output file."
                return 1
            fi
            ;;
        js)
            if [ ! -f "./$bin_dir/download.js" ]; then
                echo "JavaScript download method selected, but $bin_dir/download.js not found."
                return 1
            fi
            if ! command -v node >/dev/null 2>&1; then
                echo "Node.js is required for javascript method but not found."
                return 1
            fi
            node ./"$bin_dir"/download.js "$source" "$dest"
            if [ ! -f "$dest" ]; then
                echo "download.js did not create output file."
                return 1
            fi
            ;;
        *)
            echo "Unsupported get method: $method"
            return 1
            ;;
    esac
}

help() {
    printf '%0.s-' {1..100}; echo
    echo "bpkg.sh [-switch {subswitches} {ARG} ]"
    echo

    for switch in "${valid_switches[@]}"; do
        case "$switch" in
            get|pastebin|update|info|upgrade|verifyself)
                printf '%-40s %s\n' "[-$switch {-usemethod} ARG]" "${switch_descriptions[$switch]}"
                ;;
            list)
                printf '%-40s %s\n' "[-$switch -server {-usemethod}]" "${switch_descriptions[$switch]}"
                printf '%-40s %s\n' "[-$switch -local]" ""
                ;;
            remove)
                printf '%-40s %s\n' "[-$switch SCRIPT]" "${switch_descriptions[$switch]}"
                ;;
            help)
                printf '%-40s %s\n' "bpkg.sh -$switch" "${switch_descriptions[$switch]}"
                ;;
        esac
    done

#     printf '%-40s %s\n' "[-get {-usemethod} SCRIPT]"            "Fetches the script using the specified method."
#     printf '%-40s %s\n' "[-pastebin {-usemethod} PASTE_CODE]"   "Gets a Pastebin script using the specified method."
#     printf '%-40s %s\n' "[-remove SCRIPT]"                      "Removes the script."
#     printf '%-40s %s\n' "[-update {-usemethod} SCRIPT]"         "Fetches the script using the specified method."
#     printf '%-40s %s\n' "[-info {-usemethod} SCRIPT]"           "Gets info on the specified script."
#     printf '%-40s %s\n' "[-list -server {-usemethod}]"          "Gets the list of scripts on bpkg's server."
#     printf '%-40s %s\n' "[-list -local]"                        "Gets the list of scripts on the local computer."
#     printf '%-40s %s\n' "[-upgrade {-usemethod}]"               "Gets bpkg's latest version."
#     printf '%-40s %s\n' "[-verifyself {-usemethod}]"            "Verifies the core components of bpkg"
#     printf '%-40s %s\n' "bpkg -help"                            "Prints this help screen."

    echo
    echo "Suported methods: js (javascript), sh (bash shell), curl, wget."
    echo "Example: bpkg.sh -get -usejs test"
    printf '%0.s-' {1..100}; echo

    if [[ -n "$msg" ]]; then
        echo "$msg"
    fi

    exit 0
}

get() {
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

            if [[ -f "$scripts_dir/$name" ]]; then
                echo "Script \"$name\" is already downloaded."
                exit 1
            fi

            ((script_count++))

            echo "Fetching $name..."

            if [[ ! -d "$scripts_dir/$name" ]]; then
                mkdir "$scripts_dir/$name"
            fi

            target_path="$scripts_dir/$name/$filename"

            if ! download "$get_method" "$location" "$target_path"; then
                echo "An error occured while fetching script."
                exit 1
            fi

            if [ -f "$target_path" ]; then
                echo "$hash" > "$scripts_dir/$name/hash"
                echo "$desc" > "$scripts_dir/$name/info"
                echo "$author" > "$scripts_dir/$name/author"
                echo "Done."
            fi
        fi
    done < "$master_file"

    if [ "$script_count" -eq 0 ]; then
        echo "Script \"$script_name\" does not exist on the server."
        echo "Try deleting $master_file if you are certain it exists..."
        exit 1
    fi
}

pastebin() {
    paste_bool="off"
    paste_method=""

    echo "bpkg pastebin tip: PASTE_CODE is the unique element of a PASTEBIN url."
    echo "E.g a pastebin script located at https://pastebin.com/YkEtQYFR would have YkEtQYFR as its paste code."
    echo "If you get the paste code wrong, you'll get a pastebin error as the output file instead of your intended script."
    echo
    echo

    if [ -z "$1" ]; then
        echo "Error: No pastebin get method supplied."
        exit 1
    fi

    paste_method="$1"

    for m in "${valid_methods[@]}"; do
        if [[ "$m" == "${paste_method#-use}" ]]; then
            paste_bool="yes"
            paste_method="$m"
        fi
    done

    if [ "$paste_bool" != "yes" ]; then
        msg="Error: Invalid paste get method."
        help
        exit 1
    fi

    if [ -z "$2" ]; then
        echo "Error: No paste code supplied."
        exit 1
    fi

    paste_bool=""
    paste_code="$2"

    target_dir="$scripts_dir/pastebin/$paste_code"

    if [[ -d "$target_dir" ]]; then
        echo "Pastebin with code $2 already exists."
        exit 1
    fi

    mkdir -p "$target_dir"
    echo "Fetching $paste_code..."

    download "$paste_method" "https://pastebin.com/raw/$paste_code" "$target_dir/script.bat"

    if [[ ! -f "$target_dir/script.bat" ]]; then
        echo "An error occured fetching pastebin script."
        exit 1
    fi

    echo "Done."
    exit 0
}

main() {
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
    method="$1"

    for m in "${valid_switches[@]}"; do
        if [[ "$m" == "${method#-}" ]]; then
            method="$m"
            valid_bool="on"
            break
        fi
    done

    if [[ "$valid_bool" == "off" ]]; then
        msg="Error: Invalid switch."
        help
        exit 1
    fi

    "$method" "${@:2}"
    exit 0
}

main "$@"

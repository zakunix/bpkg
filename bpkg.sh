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

valid_switches=(help get pastebin remove update info list upgrade)
valid_methods=(js sh curl wget)
valid_list_methods=(local server)
# Major, Minor, Bugfixes/Patches
version="v2.0.0"

upgrade_file="upgrade.sh"

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

truncate() {
    local str="$1"
    local max_len=$2

    if (( ${#str} > max_len )); then
        echo "${str:0:max_len-3}..."
    else
        echo "$str"
    fi
}

trim() {
  local var="$*"
  var="${var#"${var%%[![:space:]]*}"}"
  var="${var%"${var##*[![:space:]]}"}"
  echo -n "$var"
}

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

remove() {
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

        read -p "Clear ALL your pastebin scripts? This can't be undone. [(Y)es/(N)o]" c
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
}

update() {
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
}

info() {
    info_mode="on"
    get "$@"
    info_mode="off"
    exit 0
}

list() {
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
}

upgrade() {
    upgrade_bool=""
    ugrade_method=""

    upgrade_hash_location="https://raw.githubusercontent.com/zakunix/bpkg/refs/heads/main/bin/hash"
    bpkg_location="https://raw.githubusercontent.com/zakunix/bpkg/refs/heads/main/bpkg.sh"

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

    if ! download "$upgrade_method" "$bpkg_location" "$temp_dir/bpkg.sh"; then
        echo "An error occured while fetching new bpkg."
        exit 1
    fi

    echo '#!/bin/bash' > "$upgrade_file"
    echo 'echo "Updating..."' > "$upgrade_file"
    echo 'sleep 5' >> "$upgrade_file"
    echo "mv -f $temp_dir/bpkg.sh ./bpkg.sh" >> "$upgrade_file"
    echo "echo \"$new_upgrade_hash\" > bin/hash" >> "$upgrade_file"

    chmod +x "$upgrade_file"
    ./"$upgrade_file" &

    exit 1
}

trash() {
    for var in "$@"; do
        unset "$var"
    done
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

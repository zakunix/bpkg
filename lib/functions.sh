#!/bin/bash

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
            if [ ! -f "$bin_dir/download.sh" ]; then
                echo "Bash download method selected, but $bin_dir/download.sh not found."
                echo "Downloading.."

                if ! download "-usecurl" "https://raw.githubusercontent.com/zakunix/bpkg/refs/heads/main/bin/download.sh" "$bin_dir/download.sh"; then
                    echo "An error occured while trying to download download.js"
                    return 1
                fi

                if [ -f "$bin_dir/download.sh" ]; then
                    chmod +x "./$bin_dir/download.sh"
                fi
            fi

            ./"$bin_dir"/download.sh "$source" "$dest"
            if [ ! -f "$dest" ]; then
                echo "download.sh did not create output file."
                return 1
            fi
            ;;
        js)
            if [ ! -f "$bin_dir/download.js" ]; then
                echo "JavaScript download method selected, but $bin_dir/download.js not found."
                echo "Downloading..."

                if ! download "-usecurl" "https://raw.githubusercontent.com/zakunix/bpkg/refs/heads/main/bin/download.js" "$bin_dir/download.js"; then
                    echo "An error occured while trying to download download.js"
                    return 1
                fi
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

    return 0
}

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

trash() {
    for var in "$@"; do
        unset "$var"
    done
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

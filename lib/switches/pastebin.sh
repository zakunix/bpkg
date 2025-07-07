#!/bin/bash

paste_bool="off"
paste_method=""

echo "${0#./} pastebin tip: PASTE_CODE is the unique element of a PASTEBIN url."
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

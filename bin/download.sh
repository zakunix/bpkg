#!/bin/bash

url="$1"
target="$2"

if [ -z "$url" ] || [ -z "$target" ]; then
    echo "Usage: $0 <url> <target-file>"
    exit 1
fi

if [ -f "$target" ]; then
    echo "$target already exists."
    exit 0
fi

tmpfile="${target}.tmp"

if command -v curl >/dev/null 2>&1; then
    echo "Downloading with curl: $url"
    http_status=$(curl -s -w "%{http_code}" -L -o "$tmpfile" "$url")

    if [ "$http_status" -ne 200 ]; then
        echo "FAILED to download with curl: HTTP Status $http_status"
        rm -f "$tmpfile"
        exit 1
    fi
elif command -v wget >/dev/null 2>&1; then
    echo "Downloading with wget: $url"
    wget -q --output-document="$tmpfile" "$url"

    if [ $? -ne 0 ]; then
        echo "FAILED to download with wget."
        rm -f "$tmpfile"
        exit 1
    fi
else
    echo "Error: Neither curl nor wget is installed."
    exit 1
fi

if [ ! -s "$tmpfile" ]; then
    echo "FAILED: Downloaded file is empty."
    rm -f "$tmpfile"
    exit 1
fi

mv "$tmpfile" "$target"
echo "Downloaded successfully to $target"
exit 0

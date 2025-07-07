#!/bin/bash

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

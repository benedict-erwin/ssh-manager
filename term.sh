#!/bin/bash

# Version number
version="1.0.0"

# Dependencies check
check_depend() {
    for dep; do
        command -v "$dep" >/dev/null || die "Program \"$dep\" not found. Need to install first!"
    done
}

# Print text & exit
die() {
    printc red "\n$*\n" >&2
    exit 1
}

# Print with color
# Adapted from: Alireza Mirian (2014)
# [source] https://stackoverflow.com/questions/5947742/how-to-change-the-output-color-of-echo-in-linux/23006365#23006365
printc() {
    local color=$1
    local exp=$2
    if ! [[ $color =~ '^[0-9]$' ]]; then
        case $(echo $color | tr '[:upper:]' '[:lower:]') in
        black) color=0 ;;
        red) color=9 ;;
        green) color=2 ;;
        yellow) color=3 ;;
        blue) color=4 ;;
        magenta) color=5 ;;
        cyan) color=6 ;;
        white | *) color=7 ;; # white or invalid color
        esac
    fi
    tput setaf $color
    printf "$exp"; echo
    tput sgr0
}

# Help menu
show_help() {
    clear
    echo
    printc blue "████████╗███████╗██████╗ ███╗   ███╗   ███████╗██╗  ██╗"
    printc blue "╚══██╔══╝██╔════╝██╔══██╗████╗ ████║   ██╔════╝██║  ██║"
    printc blue "   ██║   █████╗  ██████╔╝██╔████╔██║   ███████╗███████║"
    printc blue "   ██║   ██╔══╝  ██╔══██╗██║╚██╔╝██║   ╚════██║██╔══██║"
    printc blue "   ██║   ███████╗██║  ██║██║ ╚═╝ ██║██╗███████║██║  ██║"
    printc white "   Just another simple SSH Manager"
    printc green
    printc green "╔═══════════════════════════════╗"
    printc green "║       term.sh Help Menu       ║"
    printc green "╚═══════════════════════════════╝"
    printc green
    printc green "Usage: term.sh [OPTIONS]"
    printc green
    printc green "Options:"
    printc green "  ┌─────────────────────┬────────────────────────────────────────────────┐"
    printc green "  │   --help, -h        │    Show this help menu                         │"
    printc green "  ├─────────────────────┼────────────────────────────────────────────────┤"
    printc green "  │   --print, -p TEXT  │    Print the specified text                    │"
    printc green "  ├─────────────────────┼────────────────────────────────────────────────┤"
    printc green "  │   --check, -c       │    Show the current Operating System           │"
    printc green "  ├─────────────────────┼────────────────────────────────────────────────┤"
    printc green "  │   --add, -a         │    Add a new entry to the JSON file            │"
    printc green "  ├─────────────────────┼────────────────────────────────────────────────┤"
    printc green "  │   --edit, -e        │    Edit an existing entry in the JSON file     │"
    printc green "  ├─────────────────────┼────────────────────────────────────────────────┤"
    printc green "  │   --view, -v        │    View details of an entry in the JSON file   │"
    printc green "  ├─────────────────────┼────────────────────────────────────────────────┤"
    printc green "  │   --delete, -d      │    Delete an entry from the JSON file          │"
    printc green "  ├─────────────────────┼────────────────────────────────────────────────┤"
    printc green "  │   --find, -f LABEL  │    Find and display details of an entry        │"
    printc green "  │                     │    by label                                    │"
    printc green "  └─────────────────────┴────────────────────────────────────────────────┘"
}

# Check dependencies first
check_depend "jq" "fzf" || true

# Configuration
term_config_path=$HOME/.config/term-sshman
term_config_file="$term_config_path/term.conf"
if [ ! -d $term_config_path ]; then
    mkdir $term_config_path
fi
if [ ! -f $term_config_file ]; then
    touch $term_config_file
    echo "ENCRYPTION_KEY=" >> $term_config_file
    echo "SSH_CONFIG_JSON_PATH=" >> $term_config_file
fi

# Read config file
. $term_config_file

show_help
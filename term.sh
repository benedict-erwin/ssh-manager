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
    printf "$exp"
    echo
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
    printc yellow "   Just another simple SSH Manager"
    echo
    printc green "╔═══════════════════════════════╗"
    printc green "║       term.sh Help Menu       ║"
    printc green "╚═══════════════════════════════╝"
    echo
    printc green "Usage: term.sh [OPTIONS]"
    echo
    printc green "Options:"
    printc green "  ┌───────────────────────────┬─────────────────────────────────────────────────┐"
    printc green "  │ -h, --help                │  Show this help menu                            │"
    printc green "  ├───────────────────────────┼─────────────────────────────────────────────────┤"
    printc green "  │ -a, --add <TYPE>          │  Add/create a new ssh host <key|password>       │"
    printc green "  ├───────────────────────────┼─────────────────────────────────────────────────┤"
    printc green "  │ -c, --connect <ALIAS>     │  Connect to the server with alias <ALIAS>       │"
    printc green "  ├───────────────────────────┼─────────────────────────────────────────────────┤"
    printc green "  │ -d, --delete              │  Delete selected host from entry                │"
    printc green "  ├───────────────────────────┼─────────────────────────────────────────────────┤"
    printc green "  │ -e, --edit                │  Edit an existing host from entry               │"
    printc green "  ├───────────────────────────┼─────────────────────────────────────────────────┤"
    printc green "  │ -l, --list                │  List all stored host from entry,               │"
    printc green "  │                           │  then choose to execute the ssh connection      │"
    printc green "  └───────────────────────────┴─────────────────────────────────────────────────┘"
}

# Check dependencies first
check_depend "jq" "fzf" "openssl" "base64" "wc" "sshpass" || true

# Generate encryption key to use in config
gen_encrypt_key() {
    local plaintext="$1"
    local salt="mempertanggungjawabkannya"
    plaintext=$(echo "$plaintext" | xargs)
    local encryptkey=$(echo -n "$plaintext" | openssl enc -aes-256-cbc -a -A -nosalt -pbkdf2 -k "$salt" -iv "00000000000000000000000000000000" | base64 -w 0 | tr '/+' '_-')
    echo "$encryptkey"
}

# Default Configuration
term_config_path=$HOME/.config/term-sshman
term_config_file="$term_config_path/term.conf"
term_ssh_config_file="$term_config_path/ssh-config.json"
if [ ! -d $term_config_path ]; then
    mkdir $term_config_path
fi
if [ ! -f $term_config_file ]; then
    while true; do
        printc yellow "Please enter encryption key to secure your data"
        read -s -p "Encryption Key: " enckey
        if [[ -n "$enckey" ]]; then
            break
        else
            echo 
        fi
    done
    enckey=$(gen_encrypt_key "$enckey")
    touch $term_config_file
    echo "ENCRYPTION_KEY=$enckey" >>$term_config_file
fi

# Read config file
. $term_config_file

# Check json config file
check_json_config() {
    if [ ! -f $term_ssh_config_file ]; then
        die "Please add host first! Use -h or --help for usage instructions."
    fi
}

# Encrypt text with aes-256-cbc
str_encrypt() {
    local plaintext="$1"
    plaintext=$(echo "$plaintext" | xargs)
    local encrypted=$(echo -n "$plaintext" | openssl enc -aes-256-cbc -a -A -salt -pbkdf2 -k "$ENCRYPTION_KEY" | base64 -w 0)
    echo "$encrypted"
}

# Decrypt aes-256-cbc text
str_decrypt() {
    local ciphertext="$1"
    local decrypted=$(echo -n "$ciphertext" | base64 -d | openssl enc -d -aes-256-cbc -a -A -salt -pbkdf2 -k "$ENCRYPTION_KEY" 2>/dev/null)
    echo "$decrypted"
}

# IP or Domain Validation
validate_ip_or_domain() {
    local input=$1

    # Validate IP address
    # Adapted from: Neo (2016)
    # [source] https://stackoverflow.com/a/35701965
    if [[ $input =~ ^(([1-9]?[0-9]|1[0-9][0-9]|2([0-4][0-9]|5[0-5]))\.){3}([1-9]?[0-9]|1[0-9][0-9]|2([0-4][0-9]|5[0-5]))$ ]]; then
        return 0
    fi

    # Validate domain
    # Adapted from: ilkkachu (2019)
    # [source] https://unix.stackexchange.com/a/548582
    if [[ $input =~ ^([a-zA-Z0-9](([a-zA-Z0-9-]){0,61}[a-zA-Z0-9])?\.)+[a-zA-Z]{2,}$ ]]; then
        return 0
    fi

    # Invalid IP or domain
    printc yellow "Invalid IP address or domain: $input"
    return 1
}

# Validate port number
validate_port() {
    local port=$1

    # Check if the port is a number
    if [[ $port =~ ^[0-9]+$ ]]; then
        # Check if the port is within the valid range (1-65535)
        if ((port >= 1 && port <= 65535)); then
            return 0
        else
            printc yellow "Invalid port range: $port"
        fi
    else
        printc yellow "Invalid port format: $port"
    fi

    return 1
}

# Check if json key exists
check_json_key() {
    local json_key="$1"
    local json_value="$2"
    local word=$(echo "$json_value" | wc -w)
    if [ ! -f $term_ssh_config_file ]; then
        return 0
    fi
    if [ "$json_key" == "alias" ]; then
        if [ "$word" != 1 ]; then
            printc yellow "Alias should only contain one word!"
            return 1
        fi
    fi
    if jq --arg key "$json_key" --arg value "$json_value" '.[] | .[$key] == $value' "$term_ssh_config_file" | grep -q "true"; then
        printc red "$json_key: '$json_value' already exists! Please use other $json_key"
        return 1
    fi

    return 0
}

# Find json by key-value
find_by_key() {
    local json_key="$1"
    local json_value="$2"
    local matching_entry=$(jq --arg key "$json_key" --arg value "$json_value" 'map(select(.[$key] == $value)) | .[0]' "$term_ssh_config_file")

    # Check if the matching entry exists
    if [ -z "$matching_entry" ]; then
        die "No entry found with $json_key: $json_value"
    fi

    echo "${matching_entry[@]}"
}

# Create new host
create_new_host() {
    local type="$1"
    type=${type^^}
    if [[ $type == "KEY" || $type == "PASSWORD" ]]; then
        # Address validation
        while true; do
            read -p "Server address: " address
            if validate_ip_or_domain "$address"; then
                break
            else
                printc yellow "Please enter a valid server address!"
            fi
        done

        # Port validation
        while true; do
            read -p "Server port (22): " port
            port=${port:-22}
            if validate_port "$port"; then
                break
            else
                printc yellow "Please enter a valid port!"
            fi
        done

        # Key validation
        if [ $type == "KEY" ]; then
            while true; do
                read -p "Server key, full path .pem file: " key
                if [ -f "$key" ]; then
                    break
                else
                    printc yellow "Please enter correct key full path!"
                fi
            done
        fi

        # Username required validation
        if [[ $type == "PASSWORD" || $type == "KEY" ]]; then
            while true; do
                read -p "Server username: " username
                if [[ -n "$username" ]]; then
                    break
                else
                    printc yellow "Please enter server username!"
                fi
            done
        fi

        # Password required validation
        if [ $type == "PASSWORD" ]; then
            while true; do
                read -s -p "Server password: " password
                echo
                if [[ -n "$password" ]]; then
                    break
                else
                    printc yellow "Please enter server password!"
                fi
            done
        fi
        read -p "Enter startup command (optional): " startupcmd

        # Alias check
        while true; do
            read -p "Alias for this server: " alias
            if check_json_key "alias" "$alias"; then
                break
            fi
        done

        read -p "Label description for this server: " label
        read -p "Tag for this server: " tag

        # Encrypt data
        address=$(str_encrypt $address)
        port=$(str_encrypt $port)
        if [[ -n "$password" ]]; then
            password=$(str_encrypt $password)
        fi
        if [[ -n "$username" ]]; then
            username=$(str_encrypt $username)
        fi
        if [[ -n "$key" ]]; then
            key=$(str_encrypt $key)
        fi

        # Save to json
        local json_object='{"alias": "'"$alias"'", "label": "'"$label"'", "tag": "'"$tag"'", "address": "'"$address"'", "port": "'"$port"'", "username": "'"$username"'", "password": "'"$password"'", "ssh_key": "'"$key"'", "startup_cmd": "'"$startupcmd"'"}'
        if [ ! -f $term_ssh_config_file ]; then
            touch $term_ssh_config_file
            echo "[$json_object]" | jq >>$term_ssh_config_file
        else
            jq --argjson json "$json_object" '. += [$json]' "$term_ssh_config_file" >"$term_ssh_config_file.tmp" && mv "$term_ssh_config_file.tmp" "$term_ssh_config_file"
        fi

        printc green "Host '$alias' was successfully added!"
    else
        die "Invalid type! Type must be 'key' or 'password'"
    fi
}

# List all host
get_selected_host() {
    # Check file json first
    check_json_config

    # Read the JSON into a bash array
    local entries=()
    while IFS= read -r line; do
        entries+=("$line")
    done < <(jq -c '.[]' "$term_ssh_config_file")

    # Declare an array to store the keys for use with fzf
    local keys=()

    # Add header
    keys+=("#,ALIAS,ADDRESS,LABEL,TAG")

    # Iterate over the entries and process them
    for index in "${!entries[@]}"; do
        local entry="${entries[$index]}"

        # Extract the fields from the JSON object
        local alias=$(jq -r '.alias' <<<"$entry")
        local address=$(jq -r '.address' <<<"$entry")
        local label=$(jq -r '.label' <<<"$entry")
        local label=$(jq -r '.label' <<<"$entry")
        local tag=$(jq -r '.tag' <<<"$entry")
        address=$(str_decrypt "$address")

        # Create the display entry for fzf
        local display_entry="$((index + 1)),$alias,$address,$label,$tag"

        # Store the display entry in the keys array
        keys+=("$display_entry")

    done

    # Use fzf to select an entry by its key
    local selected_key=$(printf '%s\n' "${keys[@]}" | column -t -s ',' | fzf --no-select-1 --ansi --inline-info --reverse --prompt="Please select the host to proceed: ")

    # Check if selected_key not empty
    if [ -z "$selected_key" ]; then
        die "Selection canceled!"
    fi

    # Extract the index from the selected key
    local selected_index=${selected_key%% *}

    # Prevent select header
    if [ "$selected_index" == "#" ]; then
        get_selected_host
    else
        # Retrieve the corresponding entry from the entries array
        local selected_entry="${entries[$selected_index - 1]}"

        # Extract the fields from the selected entry
        local c_alias=$(jq -r '.alias' <<<"$selected_entry")
        echo "$c_alias"
    fi
}

# Delete host
delete_host() {
    # Get alias
    local alias=$(get_selected_host)

    # Delete by alias
    if [ -n "$alias" ]; then
        local json_entry=$(find_by_key "alias" "$alias")
        local c_alias=$(jq -r '.alias' <<<"$json_entry")
        local c_label=$(jq -r '.label' <<<"$json_entry")
        local c_address=$(jq -r '.address' <<<"$json_entry")
        c_address=$(str_decrypt "$c_address")

        read -p "Do you want to delete host: $c_alias [$c_address] \"$c_label\"? (no): " answer
        case "$answer" in
        [Yy] | [Yy][Ee][Ss] | [Yy][Aa][Pp])
            jq --arg ALIAS "$alias" 'flatten | map(select(type == "object")) | map(select(.alias != $ALIAS))' "$term_ssh_config_file" >"$term_ssh_config_file.tmp" && mv "$term_ssh_config_file.tmp" "$term_ssh_config_file"
            printc green "Host '$alias' has been deleted!"
            return 0
            ;;
        *)
            delete_host
            ;;
        esac

    fi
}

# Edit host
edit_host() {
    # Get alias
    local alias=$(get_selected_host)
    local method=""

    # Edit by alias
    if [ -n "$alias" ]; then
        local json_entry=$(find_by_key "alias" "$alias")
        local alias=$(jq -r '.alias' <<<"$json_entry")
        local label=$(jq -r '.label' <<<"$json_entry")
        local tag=$(jq -r '.tag' <<<"$json_entry")
        local address=$(jq -r '.address' <<<"$json_entry")
        local port=$(jq -r '.port' <<<"$json_entry")
        local username=$(jq -r '.username' <<<"$json_entry")
        local password=$(jq -r '.password' <<<"$json_entry")
        local key=$(jq -r '.ssh_key' <<<"$json_entry")
        local startup=$(jq -r '.startup_cmd' <<<"$json_entry")

        # Decrypt
        address=$(str_decrypt "$address")
        port=$(str_decrypt "$port")
        username=$(str_decrypt "$username")
        if [[ -n "$password" ]]; then
            password=$(str_decrypt $password)
            method="PASSWORD"
        fi
        if [[ -n "$key" ]]; then
            key=$(str_decrypt $key)
            method="KEY"
        fi

        read -p "Server address ($address): " c_address
        read -p "Server port ($port): " c_port
        read -p "Server username ($username): " c_username
        if [ $method == "PASSWORD" ]; then
            read -s -p "Server password (*********): " c_password
        else
            echo "Old Server key: ($key)"
            read -p "New Server key, full path .pem file: " c_key
        fi
        echo
        read -p "Server startup command ($startup): " c_startup
        read -p "Alias for this server ($alias): " c_alias
        read -p "Label description for this server ($alias): " c_label
        read -p "Tag for this server ($tag): " c_tag

        # Asign new value
        c_alias=${c_alias:-$alias}
        c_label=${c_label:-$label}
        c_tag=${c_tag:-$tag}
        c_startupcmd=${c_startupcmd:-$startupcmd}

        if [[ -n "$c_address" ]]; then
            c_address=$(str_encrypt $c_address)
        else
            if [[ -n "$address" ]]; then
                c_address=$(str_encrypt $address)
            fi
        fi

        if [[ -n "$c_port" ]]; then
            c_port=$(str_encrypt $c_port)
        else
            if [[ -n "$port" ]]; then
                c_port=$(str_encrypt $port)
            fi
        fi

        if [[ -n "$c_username" ]]; then
            c_username=$(str_encrypt $c_username)
        else
            if [[ -n "$username" ]]; then
                c_username=$(str_encrypt $username)
            fi
        fi

        if [[ -n "$c_password" ]]; then
            c_password=$(str_encrypt $c_password)
        else
            if [[ -n "$password" ]]; then
                c_password=$(str_encrypt $password)
            fi
        fi

        if [[ -n "$c_key" ]]; then
            c_key=$(str_encrypt $c_key)
        else
            if [[ -n "$key" ]]; then
                c_key=$(str_encrypt $key)
            fi
        fi

        # update json
        jq --arg alias "$alias" \
            --arg c_alias "$c_alias" \
            --arg c_label "$c_label" \
            --arg c_tag "$c_tag" \
            --arg c_address "$c_address" \
            --arg c_port "$c_port" \
            --arg c_username "$c_username" \
            --arg c_password "$c_password" \
            --arg c_key "$c_key" \
            --arg c_startupcmd "$c_startupcmd" \
            'map(if .alias == $alias 
                then 
                    .alias = $c_alias |
                    .label = $c_label |
                    .tag = $c_tag |
                    .address = $c_address |
                    .port = $c_port |
                    .username = $c_username |
                    .ssh_key = $c_key |
                    .startup_cmd = $c_startupcmd
                else . end)' "$term_ssh_config_file" >"$term_ssh_config_file.tmp"

        # Overwrite the file
        mv "$term_ssh_config_file.tmp" "$term_ssh_config_file"
        printc green "Host '$alias' was successfully updated!"
    fi
}

# Connect host to selected alias
connect_selected_host() {
    # Get alias
    local alias=$(get_selected_host)

    # Connect
    if [ -n "$alias" ]; then
        clear
        connect_host "$alias"
    fi
}

# Execute ssh connection
connect_host() {
    # Check file json first
    check_json_config

    # Define variable
    local alias="$1"
    local method=""
    local json_entry=$(find_by_key "alias" "$alias")

    # Check if alias found
    if ! echo "$json_entry" | jq -e . >/dev/null 2>&1; then
        die "Server with alias: '$alias' not found!"
    else
        # Extract data from json
        local c_alias=$(jq -r '.alias' <<<"$json_entry")
        local c_label=$(jq -r '.label' <<<"$json_entry")
        local c_address=$(jq -r '.address' <<<"$json_entry")
        local c_username=$(jq -r '.username' <<<"$json_entry")
        local c_password=$(jq -r '.password' <<<"$json_entry")
        local c_port=$(jq -r '.port' <<<"$json_entry")
        local c_key=$(jq -r '.ssh_key' <<<"$json_entry")
        local c_startup=$(jq -r '.startup_cmd' <<<"$json_entry")

        # Decrypt
        c_address=$(str_decrypt "$c_address")
        c_username=$(str_decrypt "$c_username")
        c_port=$(str_decrypt "$c_port")

        # Startup command
        if [[ -n "$c_startup" ]]; then
            c_startup="$c_startup && \$SHELL -l"
        else
            c_startup=""
        fi

        # Define method
        if [[ -n "$c_key" ]]; then
            method="KEY"
        fi
        if [[ -n "$c_password" ]]; then
            method="PASSWORD"
        fi

        # Execute ssh by method
        printc yellow "Connecting to host $c_alias..."
        if [ $method == "KEY" ]; then
            # Decrypt key
            c_key=$(str_decrypt "$c_key")

            # Execute ssh
            ssh -o StrictHostKeyChecking=no -p "$c_port" -i "$c_key" "$c_username@$c_address" -t "$c_startup"
        elif [ $method == "PASSWORD" ]; then
            # Decrypt password
            c_password=$(str_decrypt "$c_password")

            # Execute ssh
            sshpass -p "$c_password" ssh -o StrictHostKeyChecking=no -p "$c_port" "$c_username@$c_address" -t "$c_startup"
        else
            die "unsupported connection method!"
        fi
    fi

}

# Check encryption key first
check=$(jq first "$term_ssh_config_file" | jq -r '.address')
check=$(str_decrypt $check)
if [[ -z "$check" ]]; then
    die "ENCRYPTION_KEY is invalid!"
fi


# MAIN
case "$1" in
--help | -h)
    show_help
    ;;
--add | -a)
    if [ -z "$2" ]; then
        die "Error: No type provided."
    else
        create_new_host $2
    fi
    ;;
--connect | -c)
    if [ -z "$2" ]; then
        die "Error: No alias provided."
    else
        clear
        connect_host $2
    fi
    ;;
--delete | -d)
    delete_host
    ;;
--edit | -e)
    edit_host
    ;;
--list | -l)
    connect_selected_host
    ;;
*)
    printc yellow "Invalid option! Use -h or --help for usage instructions."
    ;;
esac

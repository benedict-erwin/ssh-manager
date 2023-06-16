#!/bin/bash

add_to_json() {
    local file="$1"
    local label="$2"
    local pic="$3"

    # Create the JSON object string
    local json_object='{"_id": "'$(uuidgen)'", "label": "'"$label"'", "pic": "'"$pic"'"}'

    # Check if the file exists
    if [ -f "$file" ]; then
        # File exists, append the JSON object to it
        jq --argjson json "$json_object" '. += [$json]' "$file" >"$file.tmp" && mv "$file.tmp" "$file"
    else
        # File does not exist, create a new JSON array with the object
        echo "[$json_object]" >"$file"
    fi

    echo "Data added to $file successfully."
}

edit_json() {
    local file="$1"

    # Check if the file exists
    if [ ! -f "$file" ]; then
        echo "Error: File $file does not exist."
        return 1
    fi

    # Get the list of _id values
    local ids=$(jq -r 'map(._id) | .[]' "$file")

    # Use fzf to select the _id
    local selected_id=$(echo "$ids" | fzf)

    # Check if an _id was selected
    if [ -z "$selected_id" ]; then
        echo "No _id selected."
        return 0
    fi

    # Enter interactive mode to edit the selected _id
    jq --arg selected_id "$selected_id" '.[] | select(._id == $selected_id)' "$file" | jq --indent 4

    # Prompt for the updated values
    read -rp "Enter updated label: " updated_label
    read -rp "Enter updated pic: " updated_pic

    # Update the selected _id with the new values
    jq --arg selected_id "$selected_id" --arg updated_label "$updated_label" --arg updated_pic "$updated_pic" \
        'map(if ._id == $selected_id then ._id = $selected_id | .label = $updated_label | .pic = $updated_pic else . end)' "$file" >"$file.tmp"

    # Overwrite the original file with the updated content
    mv "$file.tmp" "$file"

    echo "Entry with _id $selected_id has been updated."
}

view_detail() {
    local file="$1"

    # Check if the file exists
    if [ ! -f "$file" ]; then
        echo "Error: File $file does not exist."
        return 1
    fi

    # Get the list of labels and _ids
    local labels_ids=$(jq -r 'map({label: .label, _id: ._id}) | .[] | "\(.label)"' "$file")

    # Use fzf to select the label
    local selected_label=$(echo "$labels_ids" | fzf)

    # Check if a label was selected
    if [ -z "$selected_label" ]; then
        echo "No label selected."
        return 0
    fi

    # Get the selected _id based on the selected label
    local selected_id=$(jq -r --arg selected_label "$selected_label" 'map(select(.label == $selected_label)) | .[]._id' "$file")

    # Get the details of the selected _id
    local details=$(jq -r --arg selected_id "$selected_id" 'map(select(._id == $selected_id)) | .[0]' "$file")

    # Extract the values from the details
    local id=$(echo "$details" | jq -r '._id')
    local label=$(echo "$details" | jq -r '.label')
    local pic=$(echo "$details" | jq -r '.pic')

    # Display the details
    printf "Details:"
    echo "--------------------"
    printf "ID: %s\n" "$id"
    printf "Label: %s\n" "$label"
    printf "Pic: %s\n" "$pic"
}

delete_detail() {
    local file="$1"

    # Check if the file exists
    if [ ! -f "$file" ]; then
        echo "Error: File $file does not exist."
        return 1
    fi

    # Read the JSON file and display as a table
    local table=$(jq -r 'flatten | map(select(type == "object")) | map([._id, .label] | join("\t")) | .[]' "$file")
    if [ -z "$table" ]; then
        echo "No data found in $file."
        return 0
    fi

    # Print the table headers
    printf "%s\t%s\n" "_id" "label"
    printf "%s\n" "-------------------------------"

    # Print the table rows
    printf "%s\n" "$table"

    # Prompt for row selection
    read -p "Select a row to delete (Enter the _id): " selected_id

    # Remove the selected row from the JSON file
    jq --arg id "$selected_id" 'flatten | map(select(type == "object")) | map(select(._id != $id))' "$file" >"$file.tmp" && mv "$file.tmp" "$file"

    # Display the updated table of current data
    printf "\nData after deletion:\n"
    local updated_table=$(jq -r 'flatten | map(select(type == "object")) | map([._id, .label] | join("\t")) | .[]' "$file")
    if [ -z "$updated_table" ]; then
        echo "No data found after deletion."
    else
        # Print the table headers
        printf "%s\t%s\n" "_id" "label"
        printf "%s\n" "-------------------------------"

        # Print the table rows
        printf "%s\n" "$updated_table"
    fi
}

find_label() {
    local file="$1"
    local label="$2"

    # Check if the file exists
    if [ ! -f "$file" ]; then
        echo "Error: File $file does not exist."
        return 1
    fi

    # Find the matching entry by label
    local matching_entry=$(jq --arg LABEL "$label" 'map(select(.label == $LABEL)) | .[0]' "$file")

    # Check if the matching entry exists
    if [ -z "$matching_entry" ]; then
        echo "No entry found with label: $label"
        return 0
    fi

    # Extract the details from the matching entry
    local id=$(jq -r '._id' <<<"$matching_entry")
    local pic=$(jq -r '.pic' <<<"$matching_entry")

    # Print the details
    clear
    printf "Details for label: %s\n" "$label"
    printf "\n-------------------------------\n"
    printf "ID: %s\n" "$id"
    printf "Pic: %s\n" "$pic"
}

show_help() {
    echo "████████╗███████╗██████╗ ███╗   ███╗   ███████╗██╗  ██╗"
    echo "╚══██╔══╝██╔════╝██╔══██╗████╗ ████║   ██╔════╝██║  ██║"
    echo "   ██║   █████╗  ██████╔╝██╔████╔██║   ███████╗███████║"
    echo "   ██║   ██╔══╝  ██╔══██╗██║╚██╔╝██║   ╚════██║██╔══██║"
    echo "   ██║   ███████╗██║  ██║██║ ╚═╝ ██║██╗███████║██║  ██║"
    echo
    echo "╔═══════════════════════════════╗"
    echo "║      term.sh Help Menu        ║"
    echo "╚═══════════════════════════════╝"
    echo
    echo "Usage: term.sh [OPTIONS]"
    echo
    echo "Options:"
    echo "  ┌─────────────────────┬────────────────────────────────────────────────┐"
    echo "  │     --help, -h      │    Show help menu                              │"
    echo "  ├─────────────────────┼────────────────────────────────────────────────┤"
    echo "  │   --print, -p TEXT  │    Print the specified text                    │"
    echo "  ├─────────────────────┼────────────────────────────────────────────────┤"
    echo "  │     --check, -c     │    Show the current Operating System           │"
    echo "  ├─────────────────────┼────────────────────────────────────────────────┤"
    echo "  │      --add, -a      │    Add a new entry to the JSON file            │"
    echo "  ├─────────────────────┼────────────────────────────────────────────────┤"
    echo "  │      --edit, -e     │    Edit an existing entry in the JSON file     │"
    echo "  ├─────────────────────┼────────────────────────────────────────────────┤"
    echo "  │      --view, -v     │    View details of an entry in the JSON file   │"
    echo "  ├─────────────────────┼────────────────────────────────────────────────┤"
    echo "  │    --delete, -d     │    Delete an entry from the JSON file          │"
    echo "  ├─────────────────────┼────────────────────────────────────────────────┤"
    echo "  │   --find, -f LABEL  │    Find and display details of an entry        │"
    echo "  │                     │    by label                                    │"
    echo "  └─────────────────────┴────────────────────────────────────────────────┘"
}

print_text() {
    echo "$1"
}

check_os() {
    os=$(uname -s)
    echo "Operating System: $os"
}

case "$1" in
--help | -h)
    show_help
    ;;
--print | -p)
    if [ -z "$2" ]; then
        echo "Error: No text provided."
    else
        print_text "$2"
    fi
    ;;
--check | -c)
    check_os
    ;;
--add | -a)
    read -p "Enter the filename: " file
    read -p "Enter the label: " label
    read -p "Enter the pic: " pic
    add_to_json "$file" "$label" "$pic"
    ;;
--edit | -e)
    read -p "Enter the filename: " file
    edit_json "$file"
    ;;
--view | -v)
    read -p "Enter the filename: " file
    view_detail "$file"
    ;;
--delete | -d)
    read -p "Enter the filename: " file
    delete_detail "$file"
    ;;
--find | -f)
    find_label "$2" "$3"
    ;;
*)
    echo "Error: Invalid option. Use --help or -h for usage instructions."
    ;;
esac

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

    # Read the JSON file and display as a table
    local table=$(jq -r 'map([._id, .label] | join("\t")) | .[]' "$file")
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
    read -p "Select a row to edit (Enter the _id): " selected_id

    # Find the selected row in the JSON file
    local selected_row=$(jq --arg id "$selected_id" 'map(select(._id == $id))' "$file")

    # Check if the selected row exists
    if [ -z "$selected_row" ]; then
        echo "Error: Row with _id $selected_id not found."
        return 1
    fi

    # Prompt for field and new value
    read -p "Enter the field to edit: " field
    read -p "Enter the new value: " new_value

    # Update the selected row with the new value
    local updated_row=$(echo "$selected_row" | jq --arg field "$field" --arg value "$new_value" '.[0][$field] = $value')

    # Update the JSON file with the updated row
    jq --argjson updated_row "$updated_row" --arg id "$selected_id" '(map(if ._id == $id then $updated_row else . end))' "$file" > "$file.tmp" && mv "$file.tmp" "$file"

    echo "Data updated in $file successfully."
}

view_detail() {
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
    read -p "Select a row to view details (Enter the _id): " selected_id

    # Find the selected row in the JSON file
    local selected_row=$(jq --arg id "$selected_id" 'flatten | map(select(type == "object")) | map(select(._id == $id)) | .[0]' "$file")

    # Check if the selected row exists
    if [ -z "$selected_row" ]; then
        echo "Error: Row with _id $selected_id not found."
        return 1
    fi

    # Extract the details from the selected row
    local id=$(jq -r '._id' <<< "$selected_row")
    local label=$(jq -r '.label' <<< "$selected_row")
    local pic=$(jq -r '.pic' <<< "$selected_row")

    # Print the details
    clear
    printf "Details:"
    printf "\n--------------------\n"
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
    jq --arg id "$selected_id" 'flatten | map(select(type == "object")) | map(select(._id != $id))' "$file" > "$file.tmp" && mv "$file.tmp" "$file"

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
    local id=$(jq -r '._id' <<< "$matching_entry")
    local pic=$(jq -r '.pic' <<< "$matching_entry")

    # Print the details
    clear
    printf "Details for label: %s\n" "$label"
    printf "\n-------------------------------\n"
    printf "ID: %s\n" "$id"
    printf "Pic: %s\n" "$pic"
}


show_help() {
    echo "Usage:"
    echo "1. term.sh --help | -h (will show help menu)"
    echo "2. term.sh --print | -p <Text to print> (will print output <Text to print>)"
    echo "3. term.sh --check | -c (will show current Operating System)"
    echo "4. term.sh --add | -a (interactive option to add data to a JSON file)"
    echo "5. term.sh --edit | -e (interactive option to edit a JSON file)"
    echo "6. term.sh --view | -v (view details of a selected _id in the JSON file)"
    echo "7. term.sh --delete | -d (remove details of a selected _id in the JSON file)"
    echo "8. term.sh --find | -f <file.json> <label_name> (find detail by label in the JSON file)"
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

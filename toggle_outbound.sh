#!/bin/bash

# File to modify
target_file="/etc/V2bX/sing_origin.json"

# Ensure a tag argument is provided
if [[ -z "$1" ]]; then
    echo "Error: No tag argument provided. Usage: $0 <tag> [proxy|direct]"
    exit 1
fi

tag="$1"
explicit_change="$2"

# Ensure the file exists
if [[ ! -f "$target_file" ]]; then
    echo "Error: $target_file does not exist."
    exit 1
fi

# Read the current value of outbound
current_value=$(grep -oP '"outbound": \"\K('"$tag"'_proxy|'"$tag"'_direct)(?=\")' "$target_file")

if [[ -z "$current_value" ]]; then
    echo "Error: Could not find 'outbound' key with tag '$tag' in $target_file."
    exit 1
fi

# Determine the new value
if [[ "$explicit_change" == "proxy" ]]; then
    new_value="${tag}_proxy"
elif [[ "$explicit_change" == "direct" ]]; then
    new_value="${tag}_direct"
else
    # Toggle the value if no explicit change is provided
    if [[ "$current_value" == "${tag}_proxy" ]]; then
        new_value="${tag}_direct"
    else
        new_value="${tag}_proxy"
    fi
fi

# If the current value matches the desired value, exit without changes
if [[ "$current_value" == "$new_value" ]]; then
    echo "No changes needed. 'outbound' is already set to '$new_value'."
    exit 0
fi

# Replace the value in the file
sed -i "s/\"outbound\": \"$current_value\"/\"outbound\": \"$new_value\"/" "$target_file"

# Output the result
echo "'outbound' updated to '$new_value' using tag '$tag'."

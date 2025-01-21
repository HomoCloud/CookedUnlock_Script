#!/bin/bash

# Path to the toggle script
toggle_script="/opt/CookedUnlock/toggle_outbound.sh"
# URL to download the toggle script if not present
toggle_script_url="https://raw.githubusercontent.com/HomoCloud/CookedUnlock_Script/main/toggle_outbound.sh"

# Ensure at least one argument is provided
if [[ $# -lt 1 ]]; then
    echo "Error: No arguments provided. Usage: $0 <tag>=<direct|proxy> [<tag>=<direct|proxy> ...]"
    exit 1
fi

# Check if the toggle script exists, download if necessary
if [[ ! -f "$toggle_script" ]]; then
    echo "Toggle script not found. Downloading from $toggle_script_url..."
    curl -s -o "$toggle_script" "$toggle_script_url" || {
        echo "Error: Failed to download toggle script."
        exit 1
    }
    chmod +x "$toggle_script"
fi

# Loop through the provided arguments
for arg in "$@"; do
    # Split the argument into tag and desired value
    if [[ "$arg" =~ ^([^=]+)=(proxy|direct)$ ]]; then
        tag="${BASH_REMATCH[1]}"
        desired_value="${BASH_REMATCH[2]}"

        # Call the toggle script with the tag and desired value
        "$toggle_script" "$tag" "$desired_value"
    else
        echo "Warning: Invalid format '$arg'. Expected <tag>=<proxy|direct>. Skipping."
    fi
done

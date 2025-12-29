#!/bin/bash

# Ask the user for the migration name
echo "Enter the migration name (e.g., create recycling table):"
read raw_name

# 1. Convert to lowercase
# 2. Replace spaces with underscores
# 3. 'tr -s' squeezes multiple underscores into one
formatted_name=$(echo "$raw_name" | tr '[:upper:]' '[:lower:]' | tr ' ' '_' | tr -s '_')

# Check if the result is empty
if [ -z "$formatted_name" ]; then
    echo " Error: Migration name cannot be empty."
    exit 1
fi

echo "Creating migration: $formatted_name..."

# Execute the Supabase command
supabase migration new "$formatted_name"

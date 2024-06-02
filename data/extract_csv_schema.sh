#!/bin/bash

# Directory where the CSV files are located
SEARCH_DIR="/home/nls/data/mitma/estudios_basicos/"

# Output file to store schemas
OUTPUT_FILE="csv_schemas.txt"

# Clear output file
> "$OUTPUT_FILE"

# Temporary associative array to store directories processed
declare -A processed_dirs

# Debug function to print messages
debug() {
    echo "[DEBUG] $1"
}

# Normalize paths to avoid issues with relative paths
normalize_path() {
    local path="$1"
    echo "$(cd "$path" && pwd)"
}

# Use ls and awk to list all CSV and CSV.GZ files with their full paths
ls -R "$SEARCH_DIR" | awk '/:$/ {dir=$0; sub(/:$/,"",dir)} /\.csv$|\.csv\.gz$/ {print dir"/"$0}' | while IFS= read -r line; do
    # Check if the line contains a CSV or CSV.GZ file path
    if [[ "$line" == *.csv || "$line" == *.csv.gz ]]; then
        # Extract directory path
        debug "raw: $line"
        dir_path=$(dirname "$line")
        debug "dir_path: $dir_path"
        normalized_dir_path=$(normalize_path "$dir_path")
        debug "normalized_dir_path: $normalized_dir_path"
        # Check if this directory has already been processed
        if [ -z "${processed_dirs[$normalized_dir_path]}" ]; then
            # Mark this directory as processed
            processed_dirs[$normalized_dir_path]=1
            
            # Debug output
            debug "Processing directory: $normalized_dir_path"
            
            # Find the first CSV or CSV.GZ file in this directory recursively
            csv_file=$(find "$normalized_dir_path" -type f \( -name '*.csv' -o -name '*.csv.gz' \) -print -quit)
            
            if [ -n "$csv_file" ]; then
                debug "Found file: $csv_file"
                
                if [[ "$csv_file" == *.csv ]]; then
                    # Extract and save the schema (header) of the CSV file
                    echo "Schema for $csv_file:" >> "$OUTPUT_FILE"
                    head -n 1 "$csv_file" >> "$OUTPUT_FILE"
                    echo >> "$OUTPUT_FILE"
                elif [[ "$csv_file" == *.csv.gz ]]; then
                    # Extract and save the schema (header) of the CSV.GZ file
                    echo "Schema for $csv_file:" >> "$OUTPUT_FILE"
                    zcat "$csv_file" | head -n 1 >> "$OUTPUT_FILE"
                    echo >> "$OUTPUT_FILE"
                fi
            else
                debug "No CSV or CSV.GZ file found in $normalized_dir_path"
            fi
        else
            debug "Directory already processed: $normalized_dir_path"
        fi
    fi
done

echo "Schemas extracted to $OUTPUT_FILE"

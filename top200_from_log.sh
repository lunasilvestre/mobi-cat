#!/bin/bash

# Path to the log file
log_file="output.log"

# Check if log file exists
if [ ! -f "$log_file" ]; then
    echo "Log file not found."
    exit 1
fi

# Extract URLs and sizes, sort them by size in descending order, and get the top 5
awk '{print $(NF-1) " " $3}' "$log_file" | sort -nr | head -n 200

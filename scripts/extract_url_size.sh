#!/bin/bash

# Define the input and output file paths
input_file="../logs/size.log"
output_file="../logs/url_size.csv"

# Extract URL and size columns and save to the output file
awk '/Size of/ {
    split($0, arr, " ");
    url = arr[3];
    size = arr[9];
    print url "," size
}' $input_file > $output_file

echo "Extraction complete. Check the output file: $output_file"

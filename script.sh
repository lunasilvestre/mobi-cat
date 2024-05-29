#!/bin/bash

# Directory where the XML file is located and where downloads will be saved
DOWNLOAD_DIR="./data"
LOG_DIR="./logs"
XML_FILE="RSS.xml"

# Ensure log directory exists
mkdir -p "$LOG_DIR"

# Success and failure logs
SUCCESS_LOG="${LOG_DIR}/success.log"
FAILURE_LOG="${LOG_DIR}/failure.log"

# Read URLs from the XML file
urls=$(xmlstarlet sel -t -v "//item/link" -n $XML_FILE)

# Download each file
for url in $urls; do
  # Get the filename from the URL
  filename=$(basename "$url")
  filepath="${DOWNLOAD_DIR}/${filename}"

  # Check if the file exists
  if [ -f "$filepath" ]; then
    # Get the size of the file already downloaded
    local_size=$(stat -c%s "$filepath")

    # Get the Content-Length header from the URL
    remote_size=$(curl -sI "$url" | grep -i Content-Length | awk '{print $2}' | tr -d '\r')

    # Compare file sizes
    if [ "$local_size" -eq "$remote_size" ]; then
      echo "$filename already downloaded and size matches. Skipping..."
      echo "$url" >> "$SUCCESS_LOG"
      continue
    else
      echo "$filename exists but size mismatch. Redownloading..."
    fi
  fi

  echo "Downloading: $url"
  # Using wget to download the file, overwrite if exists
  if wget -O "$filepath" "$url"; then
    echo "$url" >> "$SUCCESS_LOG"
  else
    echo "$url" >> "$FAILURE_LOG"
  fi
done

echo "Download process completed. Check logs for details."

#!/bin/bash

# Define the path to the requirements file in GCS and the local path
GCS_REQUIREMENTS_PATH="gs://lunasilvestre.com/mitma/spark/requirements.txt"
LOCAL_REQUIREMENTS_PATH="/tmp/requirements.txt"

# Install pip if it is not already installed
if ! command -v pip &>/dev/null; then
    apt-get update || exit 1
    apt-get install -y python3-pip || exit 1
fi

# Download the requirements.txt file from GCS to a local path
if ! gsutil cp "${GCS_REQUIREMENTS_PATH}" "${LOCAL_REQUIREMENTS_PATH}"; then
    echo "Failed to download requirements file from ${GCS_REQUIREMENTS_PATH}"
    exit 1
fi

# Install Python packages from the local requirements.txt file
if ! pip install -r "${LOCAL_REQUIREMENTS_PATH}"; then
    echo "Failed to install Python packages from ${LOCAL_REQUIREMENTS_PATH}"
    exit 1
fi

echo "Initialization script completed successfully."

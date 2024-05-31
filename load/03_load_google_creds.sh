#!/bin/bash

# Function to check if gcloud is authenticated
check_gcloud_authentication() {
  gcloud auth activate-service-account --key-file "$GOOGLE_APPLICATION_CREDENTIALS"
  if [ $? -ne 0 ]; then
    echo "Error: gcloud failed to authenticate using the service account key."
    exit 1
  fi
}

# Load JSON content from Replit secret and write to a physical file
if [ ! -z "$GCLOUD_CREDENTIALS_JSON" ]; then
  echo "$GCLOUD_CREDENTIALS_JSON" > /tmp/service-account-key.json
  export GOOGLE_APPLICATION_CREDENTIALS="/tmp/service-account-key.json"
  echo "Service account key has been set successfully."
else
  echo "Error: GCLOUD_CREDENTIALS_JSON secret is not set."
  exit 1
fi

# Check if gcloud is authenticated
check_gcloud_authentication
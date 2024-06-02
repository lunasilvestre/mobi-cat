#!/bin/bash

# Set variables
PROJECT_NAME="$GCP_PROJECT_NAME"
PROJECT_ID="$GCP_PROJECT_ID"
SERVICE_ACCOUNT_NAME="$GCP_SERVICE_ACCOUNT_NAME"
KEY_FILE_PATH="./service-account-key.json"

# Authenticate with gcloud
gcloud auth login

# Set gcloud default project
gcloud config set project $PROJECT_ID

# Set SA id
SERVICE_ACCOUNT_ID="${SERVICE_ACCOUNT_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"

# Enable required services
gcloud services enable iam.googleapis.com
gcloud services enable storage.googleapis.com
gcloud services enable pubsub.googleapis.com
gcloud services enable dataproc.googleapis.com
gcloud services enable cloudfunctions.googleapis.com
gcloud services enable cloudscheduler.googleapis.com

# Create the service account if it does not exist
if ! gcloud iam service-accounts list --filter="email=${SERVICE_ACCOUNT_ID}" | grep -q ${SERVICE_ACCOUNT_ID}; then
    gcloud iam service-accounts create ${SERVICE_ACCOUNT_NAME} \
        --display-name "Service Account for MITMA Project"
fi

# Assign roles to the service account
declare -a roles=("roles/storage.admin" "roles/iam.serviceAccountUser" "roles/dataproc.editor"
                  "roles/resourcemanager.projectIamAdmin" "roles/pubsub.admin" "roles/cloudfunctions.admin"
                  "roles/cloudscheduler.admin" "roles/storage.objectAdmin" "roles/storage.objectViewer"
                  "roles/pubsub.publisher" "roles/pubsub.subscriber")

for role in "${roles[@]}"
do
    gcloud projects add-iam-policy-binding ${PROJECT_ID} \
        --member "serviceAccount:${SERVICE_ACCOUNT_ID}" \
        --role "${role}"
done

# Create and download the service account key
gcloud iam service-accounts keys create ${KEY_FILE_PATH} \
    --iam-account ${SERVICE_ACCOUNT_ID}

# Read the content of the service account key file and export it to an environment variable
export GCLOUD_CREDENTIALS_JSON=$(cat ${KEY_FILE_PATH})

echo "Service account key has been created, saved to ${KEY_FILE_PATH}, and loaded into the GCLOUD_CREDENTIALS_JSON environment variable. Please keep this file secure."
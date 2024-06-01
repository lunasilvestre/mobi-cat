#!/bin/bash

# Set variables
PROJECT_NAME="$GCP_PROJECT_NAME"
SERVICE_ACCOUNT_NAME="$GCP_SERVICE_ACCOUNT_NAME"
KEY_FILE_PATH="./service-account-key.json"

# Fetch project ID from project name
PROJECT_ID=$(gcloud projects list --filter="name=${PROJECT_NAME}" --format="value(projectId)")
if [ -z "$PROJECT_ID" ]; then
    echo "Failed to fetch Project ID for project name: $PROJECT_NAME"
    exit 1
fi
SERVICE_ACCOUNT_ID="${SERVICE_ACCOUNT_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"

# Authenticate with gcloud
gcloud auth login
gcloud config set project $PROJECT_ID

# Enable required services
gcloud services enable iam.googleapis.com
gcloud services enable storage.googleapis.com
gcloud services enable pubsub.googleapis.com
gcloud services enable container.googleapis.com

# Create the service account
gcloud iam service-accounts create ${SERVICE_ACCOUNT_NAME} \
    --display-name "Service Account for My Project"

# Assign roles to the service account
gcloud projects add-iam-policy-binding ${PROJECT_ID} \
    --member "serviceAccount:${SERVICE_ACCOUNT_ID}" \
    --role "roles/storage.admin"
gcloud projects add-iam-policy-binding ${PROJECT_ID} \
    --member "serviceAccount:${SERVICE_ACCOUNT_ID}" \
    --role "roles/iam.serviceAccountUser"
gcloud projects add-iam-policy-binding ${PROJECT_ID} \
    --member "serviceAccount:${SERVICE_ACCOUNT_ID}" \
    --role "roles/container.admin"
gcloud projects add-iam-policy-binding ${PROJECT_ID} \
    --member "serviceAccount:${SERVICE_ACCOUNT_ID}" \
    --role "roles/resourcemanager.projectIamAdmin"
gcloud projects add-iam-policy-binding ${PROJECT_ID} \
    --member "serviceAccount:${SERVICE_ACCOUNT_ID}" \
    --role "roles/pubsub.admin"
gcloud projects add-iam-policy-binding ${PROJECT_ID} \
    --member "serviceAccount:${SERVICE_ACCOUNT_ID}" \
    --role "roles/container.clusterAdmin"
gcloud projects add-iam-policy-binding ${PROJECT_ID} \
    --member "serviceAccount:${SERVICE_ACCOUNT_ID}" \
    --role "roles/container.developer"
gcloud projects add-iam-policy-binding ${PROJECT_ID} \
    --member "serviceAccount:${SERVICE_ACCOUNT_ID}" \
    --role "roles/storage.objectAdmin"
gcloud projects add-iam-policy-binding ${PROJECT_ID} \
    --member "serviceAccount:${SERVICE_ACCOUNT_ID}" \
    --role "roles/storage.objectViewer"
gcloud projects add-iam-policy-binding ${PROJECT_ID} \
    --member "serviceAccount:${SERVICE_ACCOUNT_ID}" \
    --role "roles/pubsub.publisher"
gcloud projects add-iam-policy-binding ${PROJECT_ID} \
    --member "serviceAccount:${SERVICE_ACCOUNT_ID}" \
    --role "roles/pubsub.subscriber"

# Create and download the service account key
gcloud iam service-accounts keys create ${KEY_FILE_PATH} \
    --iam-account ${SERVICE_ACCOUNT_ID}

# Read the content of the service account key file and export it to an environment variable
export GCLOUD_CREDENTIALS_JSON=$(cat ${KEY_FILE_PATH})

echo "Service account key has been created, saved to ${KEY_FILE_PATH}, and loaded into the GCLOUD_CREDENTIALS_JSON environment variable. Please keep this file secure."
#!/bin/bash

# Exit when any command fails
set -e

# Check if required environment variables are set
: "${GOOGLE_APPLICATION_CREDENTIALS:?Environment variable GOOGLE_APPLICATION_CREDENTIALS is required}"
: "${GCP_PROJECT_NAME:?Environment variable GCP_PROJECT_NAME is required}"
: "${GCP_REGION:?Environment variable GCP_REGION is required}"
: "${GCS_BUCKET_NAME:?Environment variable GCS_BUCKET_NAME is required}"
: "${K8S_CLUSTER_NAME:?Environment variable K8S_CLUSTER_NAME is required}"
: "${PUBSUB_TOPIC_NAME:?Environment variable PUBSUB_TOPIC_NAME is required}"
: "${PUBSUB_SUBSCRIPTION_NAME:?Environment variable PUBSUB_SUBSCRIPTION_NAME is required}"

# Export temporary environment variables for Terraform
export TF_VAR_gcp_credentials_file="$GOOGLE_APPLICATION_CREDENTIALS"
export TF_VAR_project_id="$GCP_PROJECT_NAME"
export TF_VAR_region="$GCP_REGION"
export TF_VAR_bucket_name="$GCS_BUCKET_NAME"
export TF_VAR_k8s_cluster_name="$K8S_CLUSTER_NAME"
export TF_VAR_pubsub_topic_name="$PUBSUB_TOPIC_NAME"
export TF_VAR_pubsub_subscription_name="$PUBSUB_SUBSCRIPTION_NAME"

# Initialize and deploy with Terraform
terraform plan
# terraform init
# terraform apply -auto-approve

# Unset temporary environment variables
# unset TF_VAR_gcp_credentials_file
# unset TF_VAR_project_id
# unset TF_VAR_region
# unset TF_VAR_bucket_name
# unset TF_VAR_k8s_cluster_name
# unset TF_VAR_pubsub_topic_name
# unset TF_VAR_pubsub_subscription_name
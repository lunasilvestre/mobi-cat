#!/bin/bash

# Set variables
PROJECT_ID=${GCP_PROJECT_ID}
SUBSCRIPTION_ID=${PUBSUB_SUBSCRIPTION_NAME}
GCS_BUCKET=${GCS_BUCKET_NAME}
DATAFLOW_TMP_BUCKET=${CLUSTER_TMP_BUCKET_NAME}
CLUSTER_NAME=${CLUSTER_NAME}
REGION=${GCP_REGION}

# Check if required environment variables are set
if [ -z "$PROJECT_ID" ] || [ -z "$SUBSCRIPTION_ID" ] || [ -z "$GCS_BUCKET" ] || [ -z "$REGION" ] || [ -z "$CLUSTER_NAME" ]; then
  echo "One of the required environment variables (GCP_PROJECT_ID, PUBSUB_SUBSCRIPTION_NAME, GCS_BUCKET_NAME, GCP_REGION, CLUSTER_NAME) is not set."
  exit 1
fi

# Read the job ID from the file
if [ ! -f job_id.txt ]; then
  echo "Job ID file not found."
  exit 1
fi
DATAPROC_JOB_ID=$(cat job_id.txt)

# Function to check the queue length
check_queue_length() {
  # Get the number of unprocessed messages in the Pub/Sub subscription
  MESSAGE_COUNT=$(gcloud pubsub subscriptions describe $SUBSCRIPTION_ID --format="value(ackDeadlineSeconds)")

  if [ -z "$MESSAGE_COUNT" ]; then
    echo "Failed to retrieve the queue length. Check that the subscription $SUBSCRIPTION_ID in project $PROJECT_ID exists and is accessible."
    exit 1
  fi

  echo "Number of messages in the queue: $MESSAGE_COUNT"
}

# Function to check if files are being uploaded to GCS
check_gcs_uploads() {
  echo "Checking if files are being uploaded to GCS bucket $GCS_BUCKET..."
  gsutil ls "gs://$GCS_BUCKET/mitma/spark/*"

  if [ $? -ne 0 ]; then
    echo "Failed to access GCS bucket $GCS_BUCKET or no files are present."
    exit 1
  else
    echo "Files found in GCS bucket $GCS_BUCKET."
  fi
}

# Function to check the status of the Dataproc job
check_dataproc_job_status() {
  echo "Checking Dataproc job status..."

  JOB_STATUS=$(gcloud dataproc jobs describe $DATAPROC_JOB_ID --region=$REGION --format="value(status.state)")

  if [ -z "$JOB_STATUS" ]; then
    echo "Failed to retrieve job status. Check that the Dataproc job ID and region are correct."
    exit 1
  fi

  echo "Dataproc job status: $JOB_STATUS"

  if [ "$JOB_STATUS" != "DONE" ]; then
    echo "Dataproc job is not completed yet. Current status: $JOB_STATUS"
    exit 1
  fi

  echo "Dataproc job finished successfully."
}

# Main script execution
echo "Checking the queue length..."
check_queue_length

echo "Checking GCS uploads..."
check_gcs_uploads

echo "Checking Dataproc job status..."
check_dataproc_job_status

echo "All checks completed successfully."
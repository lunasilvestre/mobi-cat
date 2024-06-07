#!/bin/bash

# Navigate to the directory containing the cloud function code
cd cloud-function/

# Validate directory change
if [ $? -ne 0 ]; then
    echo "Failed to change directory to cloud-function/. Ensure the path exists."
    exit 1
fi

# Deploy the cloud function
gcloud functions deploy $SCHEDULED_FUNCTION_NAME \
--runtime python39 \
--trigger-http \
--set-env-vars GCP_PROJECT_ID=$GCP_PROJECT_ID,CLUSTER_NAME=$CLUSTER_NAME,GCP_REGION=$GCP_REGION,PUBSUB_SUBSCRIPTION_NAME=$PUBSUB_SUBSCRIPTION_NAME,SCHEDULER_JOB_NAME=$SCHEDULER_JOB_NAME \
--allow-unauthenticated \
--region ${GCP_REGION} \
--project ${GCP_PROJECT_ID}

# Check the deploy command result
if [ $? -ne 0 ]; then
    echo "Failed to deploy the Cloud Function."
    exit 1
fi

# Wait while function is not available
while true; do
    FUNCTION_STATUS=$(gcloud functions describe $SCHEDULED_FUNCTION_NAME --region=$GCP_REGION --project ${GCP_PROJECT_ID} --format="value(status)")
    if [ "$FUNCTION_STATUS" == "ACTIVE" ]; then
        CLOUD_FUNCTION_URL=$(gcloud functions describe $SCHEDULED_FUNCTION_NAME --region=$GCP_REGION --project ${GCP_PROJECT_ID} --format="value(httpsTrigger.url)")
        break
    else
        echo "Function status is '$FUNCTION_STATUS'. Waiting for it to become ACTIVE..."
        sleep 10
    fi
done

# Ensure the URL is retrieved successfully
if [ -z "$CLOUD_FUNCTION_URL" ]; then
  echo "Failed to retrieve the Cloud Function URL."
  exit 1
fi

# Create a Cloud Scheduler job to trigger the function at intervals
gcloud scheduler jobs create http $SCHEDULER_JOB_NAME \
--schedule "*/5 * * * *" \
--uri $CLOUD_FUNCTION_URL \
--http-method GET \
--location $GCP_REGION \
--project $GCP_PROJECT_ID

if [ $? -ne 0 ]; then
    echo "Failed to create Cloud Scheduler job."
    exit 1
fi

echo "Cloud Scheduler job created successfully."
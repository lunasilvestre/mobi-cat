#!/bin/bash

gcloud functions deploy $SCHEDULED_FUNCTION_NAME \
--runtime python39 \
--trigger-http \
--set-env-vars GCP_PROJECT_ID=$GCP_PROJECT_ID,CLUSTER_NAME=$CLUSTER_NAME,GCP_REGION=$GCP_REGION,PUBSUB_SUBSCRIPTION_NAME=$PUBSUB_SUBSCRIPTION_NAME,SCHEDULER_JOB_NAME=$SCHEDULER_JOB_NAME \
--allow-unauthenticated

# Wait while function is not available
while true; do
    if gcloud functions describe $SCHEDULED_FUNCTION_NAME --region=$GCP_REGION | grep "status: READY"; then
        CLOUD_FUNCTION_URL=$(gcloud functions describe $SCHEDULED_FUNCTION_NAME --region=$GCP_REGION --format="value(httpsTrigger.url)")
        break
    else
        echo "Function not yet available. Waiting..."
        sleep 10
    fi
done

# Create a schedule to check if there is a message in the Pub/Sub subscription every 5 minutes
# Destroy the cluster otherwise
gcloud scheduler jobs create http $SCHEDULER_JOB_NAME \
--schedule "*/5 * * * *" \
--uri $CLOUD_FUNCTION_URL \
--http-method GET \
--location $GCP_REGION
#!/bin/bash

gcloud dataproc clusters create ${CLUSTER_NAME} \
  --region ${GCP_REGION} \
  --zone "" \
  --master-machine-type n1-standard-2 \
  --worker-machine-type n1-standard-1 \
  --num-masters 1 \
  --num-workers 2 \
  --num-secondary-workers 1 \
  --worker-boot-disk-size 50GB \
  --image-version 1.5-debian10 \
  --initialization-actions gs://${GCS_BUCKET_NAME}/mitma/spark/init-script.sh \
  --properties "spark-env:GCP_PROJECT_ID=${GCP_PROJECT_ID},spark-env:PUBSUB_SUBSCRIPTION_NAME=${PUBSUB_SUBSCRIPTION_NAME},spark-env:GCS_BUCKET_NAME=${GCS_BUCKET_NAME},spark-env:GCP_REGION=${GCP_REGION}" \
  --scopes 'https://www.googleapis.com/auth/cloud-platform','https://www.googleapis.com/auth/pubsub' \
  --project ${GCP_PROJECT_ID}

# Check if the cluster creation was successful
if [ $? -eq 0 ]; then
  echo "Dataproc cluster ${CLUSTER_NAME} created successfully in region ${GCP_REGION}."
else
  echo "Failed to create Dataproc cluster ${CLUSTER_NAME} in region ${GCP_REGION}."
fi
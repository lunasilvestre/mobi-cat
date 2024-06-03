#!/bin/bash

# Define default values if they are not provided
CLUSTER_NAME="${CLUSTER_NAME:-mitma-processing-cluster}"
REGION="${REGION:-europe-west1}"

# Deleting the Dataproc cluster
gcloud dataproc clusters delete ${CLUSTER_NAME} --region ${REGION} --quiet

if [ $? -eq 0 ]; then
  echo "Dataproc cluster ${CLUSTER_NAME} deleted successfully in region ${REGION}."
else
  echo "Failed to delete Dataproc cluster ${CLUSTER_NAME} in region ${REGION}."
  exit 1
fi
#!/bin/bash

# Required environment variables
REQUIRED_ENV_VARS=("GCP_PROJECT_ID" "GCP_REGION" "GCS_BUCKET_NAME" "CLUSTER_NAME" "PUBSUB_SUBSCRIPTION_NAME" "GOOGLE_APPLICATION_CREDENTIALS")

# Loop through each required environment variable and check if it's set
for var in "${REQUIRED_ENV_VARS[@]}"
do
  if [ -z "${!var}" ]; then
    echo "Required environment variable $var is not set."
    exit 1
  fi
done

GCP_PROJECT_ID=${GCP_PROJECT_ID}
GCP_REGION=${GCP_REGION}
GCS_BUCKET_NAME=${GCS_BUCKET_NAME}
CLUSTER_NAME=${CLUSTER_NAME}
SPARK_JOB_FILE="spark_job.py"
REQUIREMENTS_FILE="requirements.txt"
GCS_SPARK_JOB_PATH="gs://${GCS_BUCKET_NAME}/mitma/spark/${SPARK_JOB_FILE}"
GCS_REQUIREMENTS_PATH="gs://${GCS_BUCKET_NAME}/mitma/spark/${REQUIREMENTS_FILE}"

# Authenticate with gcloud
gcloud auth activate-service-account --key-file $GOOGLE_APPLICATION_CREDENTIALS || { echo "Failed to activate service account."; exit 1; }

# Submit the job to the Dataproc cluster
echo "Submitting Dataproc job..."
JOB_OUTPUT=$(gcloud dataproc jobs submit pyspark ${GCS_SPARK_JOB_PATH} \
    --cluster ${CLUSTER_NAME} \
    --region ${GCP_REGION} \
    --project ${GCP_PROJECT_ID} \
    --jars gs://spark-lib/bigquery/spark-bigquery-latest_2.12.jar \
    --files ${GCS_REQUIREMENTS_PATH} \
    --py-files ${GCS_REQUIREMENTS_PATH} \
    --properties "spark.pyspark.python=python3,spark.executorEnv.GCP_PROJECT_ID=${GCP_PROJECT_ID},spark.executorEnv.PUBSUB_SUBSCRIPTION_NAME=${PUBSUB_SUBSCRIPTION_NAME},spark.executorEnv.GCS_BUCKET_NAME=${GCS_BUCKET_NAME},spark.executorEnv.GCP_REGION=${GCP_REGION}")

if [ $? -eq 0 ]; then
    echo "Dataproc job submitted successfully."
else
    echo "Failed to submit Dataproc job."
    exit 1
fi

# Extract the job ID from the output and store it in a file
JOB_ID=$(echo "$JOB_OUTPUT" | grep -oP '(?<=Job ID: )[a-zA-Z0-9_-]+')
echo "$JOB_ID" > job_id.txt
echo "Job ID: $JOB_ID"
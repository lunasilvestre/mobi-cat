#!/bin/bash

GCP_PROJECT_ID=${GCP_PROJECT_ID}
GCP_REGION=${GCP_REGION}
GCS_BUCKET_NAME=${GCS_BUCKET_NAME}
CLUSTER_NAME=${CLUSTER_NAME}
SPARK_JOB_FILE="spark_job.py"
GCS_SPARK_JOB_PATH="gs://${GCS_BUCKET_NAME}/mitma/spark/${SPARK_JOB_FILE}"

# Authenticate with gcloud
gcloud auth activate-service-account --key-file $GOOGLE_APPLICATION_CREDENTIALS

# Upload spark_job.py to GCS before submitting the job
echo "Uploading ${SPARK_JOB_FILE} to ${GCS_SPARK_JOB_PATH}..."
gsutil cp ${SPARK_JOB_FILE} ${GCS_SPARK_JOB_PATH}
if [ $? -ne 0 ]; then
    echo "Failed to upload ${SPARK_JOB_FILE} to GCS."
    exit 1
fi
echo "Successfully uploaded ${SPARK_JOB_FILE} to ${GCS_SPARK_JOB_PATH}."

# Submit the job to the Dataproc cluster
echo "Submitting Dataproc job..."
gcloud dataproc jobs submit pyspark ${GCS_SPARK_JOB_PATH} \
    --cluster ${CLUSTER_NAME} \
    --region ${GCP_REGION} \
    --jars gs://spark-lib/bigquery/spark-bigquery-latest_2.12.jar

if [ $? -eq 0 ]; then
    echo "Dataproc job submitted successfully."
else
    echo "Failed to submit Dataproc job."
    exit 1
fi

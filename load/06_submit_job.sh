#!/bin/bash

GCP_PROJECT_ID=${GCP_PROJECT_ID}
GCP_REGION=${GCP_REGION}
GCS_BUCKET_NAME=${GCS_BUCKET_NAME}
CLUSTER_NAME=${CLUSTER_NAME}
SPARK_JOB_FILE="spark_job.py"
REQUIREMENTS_FILE="requirements.txt"
GCS_SPARK_JOB_PATH="gs://${GCS_BUCKET_NAME}/mitma/spark/${SPARK_JOB_FILE}"
GCS_REQUIREMENTS_PATH="gs://${GCS_BUCKET_NAME}/mitma/spark/${REQUIREMENTS_FILE}"

# Authenticate with gcloud
gcloud auth activate-service-account --key-file $GOOGLE_APPLICATION_CREDENTIALS

# # Upload spark_job.py and requirements.txt to GCS before submitting the job
# echo "Uploading ${SPARK_JOB_FILE} to ${GCS_SPARK_JOB_PATH}..."
# gsutil cp spark/${SPARK_JOB_FILE} ${GCS_SPARK_JOB_PATH}
# if [ $? -ne 0 ]; then
#     echo "Failed to upload ${SPARK_JOB_FILE} to GCS."
#     exit 1
# fi
# echo "Successfully uploaded ${SPARK_JOB_FILE} to ${GCS_SPARK_JOB_PATH}."

# echo "Uploading ${REQUIREMENTS_FILE} to ${GCS_REQUIREMENTS_PATH}..."
# gsutil cp ${REQUIREMENTS_FILE} ${GCS_REQUIREMENTS_PATH}
# if [ $? -ne 0 ]; then
#     echo "Failed to upload ${REQUIREMENTS_FILE} to GCS."
#     exit 1
# fi
# echo "Successfully uploaded ${REQUIREMENTS_FILE} to ${GCS_REQUIREMENTS_PATH}."

# Submit the job to the Dataproc cluster
echo "Submitting Dataproc job..."
gcloud dataproc jobs submit pyspark ${GCS_SPARK_JOB_PATH} \
    --cluster ${CLUSTER_NAME} \
    --region ${GCP_REGION} \
    --jars gs://spark-lib/bigquery/spark-bigquery-latest_2.12.jar \
    --files ${GCS_REQUIREMENTS_PATH} \
    --py-files ${GCS_REQUIREMENTS_PATH} \
    --properties=spark.pyspark.python=python3,dataproc.python.library=${GCS_REQUIREMENTS_PATH}

if [ $? -eq 0 ]; then
    echo "Dataproc job submitted successfully."
else
    echo "Failed to submit Dataproc job."
    exit 1
fi

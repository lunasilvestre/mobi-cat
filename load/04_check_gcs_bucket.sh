#!/bin/bash
# check_and_upload_gcs_bucket.sh

# Set environment variables
BUCKET_NAME=${GCS_BUCKET_NAME}

# Check if the bucket exists and is accessible
if gsutil ls -b gs://$BUCKET_NAME; then
  echo "Bucket exists and is accessible."
else
  echo "Bucket does not exist or is not accessible. Exiting."
  exit 1
fi

# Upload necessary files to the bucket
gsutil cp spark/requirements.txt gs://$BUCKET_NAME/mitma/spark/
gsutil cp spark/spark_job.py gs://$BUCKET_NAME/mitma/spark/
gsutil cp spark/init-script.sh gs://$BUCKET_NAME/mitma/spark/

echo "Required files uploaded to gs://$BUCKET_NAME/mitma/spark/"

# End of script
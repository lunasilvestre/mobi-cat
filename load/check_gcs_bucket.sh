# check_gcs_bucket.sh
BUCKET_NAME="your-bucket-name"

if gsutil ls -b gs://$BUCKET_NAME; then
  echo "Bucket exists and accessible."
else
  echo "Bucket does not exist or not accessible."
  exit 1
fi

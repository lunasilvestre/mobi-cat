#!/bin/bash

# Load environment variables from .env file if it exists
if [ -f .env ]; then
  export $(cat .env | xargs)
fi

# Initialize Terraform with environment variables
terraform init

# Apply the Terraform configuration with environment variables
terraform apply -auto-approve \
  -var "region=${AWS_REGION}" \
  -var "lambda_function_name=${LAMBDA_FUNCTION_NAME}" \
  -var "main_queue_name=${MAIN_QUEUE_NAME}" \
  -var "dlq_name=${DLQ_NAME}" \
  -var "s3_bucket_name=${S3_BUCKET_NAME}" \
  -var "s3_key_prefix=${S3_KEY_PREFIX}"

# Output the SQS queue URLs
terraform output main_queue_url
terraform output dlq_url
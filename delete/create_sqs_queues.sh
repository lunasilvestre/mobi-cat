#!/bin/bash

# Variables
REGION="eu-south-2"
MAIN_QUEUE_NAME="mitma-queue"
DLQ_NAME="mitma-dlq"
VISIBILITY_TIMEOUT="600"  # 10 minutes
MESSAGE_RETENTION_PERIOD="3600"  # 1 hour
MAX_RECEIVE_COUNT="5"  # Maximum number of receives before moving to DLQ

# Create the Dead-Letter Queue (DLQ)
DLQ_URL=$(aws sqs create-queue --queue-name $DLQ_NAME --attributes VisibilityTimeout=$VISIBILITY_TIMEOUT,MessageRetentionPeriod=$MESSAGE_RETENTION_PERIOD --region $REGION --query 'QueueUrl' --output text)

# Create the Main Queue
MAIN_QUEUE_URL=$(aws sqs create-queue --queue-name $MAIN_QUEUE_NAME --attributes VisibilityTimeout=$VISIBILITY_TIMEOUT,MessageRetentionPeriod=$MESSAGE_RETENTION_PERIOD --region $REGION --query 'QueueUrl' --output text)

# Get the ARN of the DLQ
DLQ_ARN=$(aws sqs get-queue-attributes --queue-url $DLQ_URL --attribute-name QueueArn --region $REGION --query 'Attributes.QueueArn' --output text)

# Set the Redrive Policy for the Main Queue
REDRIVE_POLICY='{"deadLetterTargetArn":"'"$DLQ_ARN"'","maxReceiveCount":"'"$MAX_RECEIVE_COUNT"'"}'
# REDRIVE_POLICY="{\"deadLetterTargetArn\":\"$DLQ_ARN\",\"maxReceiveCount\":\"$MAX_RECEIVE_COUNT\"}"

# Apply the Redrive Policy to the Main Queue
aws sqs set-queue-attributes --queue-url $MAIN_QUEUE_URL --attributes RedrivePolicy="$REDRIVE_POLICY" --region $REGION

# Output the URLs for verification
echo "Main Queue URL: $MAIN_QUEUE_URL"
echo "DLQ URL: $DLQ_URL"

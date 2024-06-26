#!/bin/bash

# Variables
AWS_REGION="your-region"
ACCOUNT_ID="your-account-id"
ECR_REPO="process-tar-file"
IMAGE_TAG="latest"

# Authenticate Docker to the Amazon ECR registry
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com

# Build the Docker image
docker build -t $ECR_REPO .

# Tag the Docker image
docker tag $ECR_REPO:latest $ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPO:$IMAGE_TAG

# Push the Docker image to ECR
docker push $ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPO:$IMAGE_TAG
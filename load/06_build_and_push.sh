# build_and_push.sh
#!/bin/bash

# Define the image name
IMAGE_NAME="gcr.io/$GCP_PROJECT_ID/downloader:latest"

# Build the Docker image
docker build -t $IMAGE_NAME .

# Push the Docker image to Google Container Registry
docker push $IMAGE_NAME

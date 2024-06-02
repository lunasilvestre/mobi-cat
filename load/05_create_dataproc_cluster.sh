#!/bin/bash

gcloud dataproc clusters create ${CLUSTER_NAME} \
--region ${GCP_REGION} \
--master-machine-type n1-standard-1 \
--worker-machine-type n1-standard-1 \
--num-workers 1 \
--num-preemptible-workers 3 \
--worker-boot-disk-size 50GB \
--image-version 1.5-debian10 \
--initialization-actions gs://${GCS_BUCKET_NAME}/mitma/spark/init-script.sh

echo "Dataproc cluster ${CLUSTER_NAME} created successfully in region ${GCP_REGION}."
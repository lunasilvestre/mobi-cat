variable "gcp_credentials_file" {
  description = "Path to the Google Cloud credentials file"
}

variable "project_id" {
  description = "The GCP project ID"
}

variable "region" {
  description = "The GCP region to deploy resources"
}

variable "bucket_name" {
  description = "The GCS bucket name"
}

variable "k8s_cluster_name" {
  description = "The name of the Kubernetes cluster"
}

variable "pubsub_topic_name" {
  description = "The name of the Google Pub/Sub Topic"
}

variable "pubsub_subscription_name" {
  description = "The name of the Google Subscription"
}


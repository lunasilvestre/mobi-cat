terraform {
  required_version = ">= 0.13"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 3.5"
    }
  }

  backend "gcs" {
    bucket  = var.bucket_name
    prefix  = "mitma/tf/state"
  }
}

provider "google" {
  credentials = file(var.gcp_credentials_file)
  project     = var.project_id
  region      = var.region
}

variable "gcp_credentials_file" {
  description = "Path to the Google Cloud credentials file"
}

variable "project_id" {
  description = "The GCP project ID"
  default     = "$GCP_PROJECT_ID"
}

variable "region" {
  description = "The GCP region to deploy resources"
  default     = "$GCP_REGION"
}

variable "bucket_name" {
  description = "The GCS bucket name"
  default     = "$GCS_BUCKET_NAME"
}

variable "k8s_cluster_name" {
  description = "The name of the Kubernetes cluster"
  default     = "$K8S_CLUSTER_NAME"
}

# GKE Cluster Configuration with Preemptible VMs
resource "google_container_cluster" "primary" {
  name     = var.k8s_cluster_name
  location = var.region

  initial_node_count = 1

  node_config {
    preemptible  = true
    machine_type = "e2-micro"

    oauth_scopes = [
      "https://www.googleapis.com/auth/devstorage.read_write",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/pubsub",
      "https://www.googleapis.com/auth/service.management",
      "https://www.googleapis.com/auth/servicecontrol",
      "https://www.googleapis.com/auth/compute",
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }

  node_pool {
    name       = "my-node-pool"
    node_count = 1
  }
}

variable "pubsub_topic_name" {
  description = "The name of the Google Pub/Sub Topic"
  default     = "$PUBSUB_TOPIC_NAME"
}

variable "pubsub_subscription_name" {
  description = "The name of the Google Subscription"
  default     = "$PUBSUB_SUBSCRIPTION_NAME"
}

# Google Pub/Sub Topic for initiating tasks
resource "google_pubsub_topic" "main_topic" {
  name = var.pubsub_topic_name
}

# Google Pub/Sub Subscription for processing tasks
resource "google_pubsub_subscription" "main_subscription" {
  name  = var.pubsub_subscription_name
  topic = google_pubsub_topic.main_topic.id

  ack_deadline_seconds = 20
}

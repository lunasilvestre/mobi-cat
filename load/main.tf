terraform {
  required_version = ">= 0.13"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 3.5"
    }
  }

  backend "gcs" {
    bucket  = "your-terraform-state-bucket"
    prefix  = "terraform/state"
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
}

variable "region" {
  description = "The GCP region to deploy resources"
}

# GKE Cluster Configuration with Preemptible VMs
resource "google_container_cluster" "primary" {
  name     = "preemptible-cluster"
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

# Google Pub/Sub Topic for initiating tasks
resource "google_pubsub_topic" "main_topic" {
  name = "file-download-topic"
}

# Google Pub/Sub Subscription for processing tasks
resource "google_pubsub_subscription" "main_subscription" {
  name  = "file-download-subscription"
  topic = google_pubsub_topic.main_topic.id

  ack_deadline_seconds = 20
}

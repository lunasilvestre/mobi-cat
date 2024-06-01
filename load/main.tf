terraform {
  required_version = ">= 0.13"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 3.5"
    }
  }

  backend "gcs" {
    bucket  = "lunasilvestre.com"
    prefix  = "mitma/tf/state"
  }
}

provider "google" {
  credentials = file(var.gcp_credentials_file)
  project     = var.project_id
  region      = var.region
}

# GKE Cluster Configuration with Preemptible VMs
resource "google_container_cluster" "primary" {
  name     = var.k8s_cluster_name
  location = var.region

  # Remove the conflicted node_config; use separate node pools
  initial_node_count = 1
}

resource "google_container_node_pool" "primary_nodes" {
  cluster    = google_container_cluster.primary.name
  name       = "primary-node-pool"
  location   = var.region

  node_config {
    preemptible  = true
    machine_type = "e2-micro"
    disk_size_gb = 10

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

  initial_node_count = 3
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

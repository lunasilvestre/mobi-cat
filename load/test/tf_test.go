package test

import (
    "os"
    "testing"
    "github.com/gruntwork-io/terratest/modules/terraform"
    "github.com/stretchr/testify/assert"
)

func TestTerraform(t *testing.T) {
    t.Parallel()

    // Set Terraform options
    terraformOptions := &terraform.Options{
        TerraformDir: "../load",
        Vars: map[string]interface{}{
            "gcp_credentials_file": os.Getenv("GOOGLE_APPLICATION_CREDENTIALS"),
            "project_id":           os.Getenv("GCP_PROJECT_ID"),
            "region":               os.Getenv("GCP_REGION"),
            "bucket_name":          os.Getenv("GCS_BUCKET_NAME"),
            "k8s_cluster_name":     os.Getenv("K8S_CLUSTER_NAME"),
            "pubsub_topic_name":    os.Getenv("PUBSUB_TOPIC_NAME"),
            "pubsub_subscription_name": os.Getenv("PUBSUB_SUBSCRIPTION_NAME"),
        },
    }

    // Ensure resources are destroyed at the end of the test
    defer terraform.Destroy(t, terraformOptions)

    // Run terraform init and apply
    terraform.InitAndApply(t, terraformOptions)

    // Validate the outputs or resources
    k8sCluster := terraform.Output(t, terraformOptions, "k8s_cluster_name")
    assert.Equal(t, os.Getenv("K8S_CLUSTER_NAME"), k8sCluster)
}
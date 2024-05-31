#!/bin/bash

# Initialize Terraform
terraform init

# Apply Terraform configuration, with auto-approve to avoid interactive confirmations
terraform apply -auto-approve
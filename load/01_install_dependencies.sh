#!/bin/bash

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Update package list and install prerequisites
sudo apt-get update

# Install Terraform
if ! command_exists terraform; then
    echo "Terraform not found, installing Terraform..."

    # Download Terraform
    wget https://releases.hashicorp.com/terraform/1.0.11/terraform_1.0.11_linux_amd64.zip

    # Unzip and move to /usr/local/bin
    unzip terraform_1.0.11_linux_amd64.zip
    sudo mv terraform /usr/local/bin/

    # Cleanup
    rm terraform_1.0.11_linux_amd64.zip
else
    echo "Terraform already installed."
fi

# Install Docker
if ! command_exists docker; then
    echo "Docker not found, installing Docker..."

    # Install Docker using convenience script from Docker
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh

    # Cleanup
    rm get-docker.sh
else
    echo "Docker already installed."
fi

# Install Python dependencies
echo "Installing Python dependencies..."
pip install google-cloud-pubsub xml

echo "All dependencies installed successfully."#!/bin/bash

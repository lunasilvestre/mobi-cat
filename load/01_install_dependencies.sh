#!/bin/bash

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Update package list and install prerequisites
sudo apt-get update

# Install gcloud SDK
if ! command_exists gcloud; then
    echo "gcloud not found, installing gcloud SDK..."

    # Add gcloud SDK repository
    echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] http://packages.cloud.google.com/apt cloud-sdk main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
    sudo apt-get install -y apt-transport-https ca-certificates gnupg
    curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key --keyring /usr/share/keyrings/cloud.google.gpg add -

    # Install gcloud SDK
    sudo apt-get update && sudo apt-get install -y google-cloud-sdk
else
    echo "gcloud SDK already installed."
fi

# Check if Python3 and python3-venv are installed
if ! command_exists python3; then
    echo "Python3 not found, installing Python3..."
    sudo apt-get install -y python3 python3-pip
fi

if ! dpkg -l | grep -qw python3-venv; then
    echo "python3-venv package not found, installing python3-venv..."
    sudo apt-get install -y python3-venv
fi

# Create the virtual environment
if [ ! -d "venv" ]; then
    python3 -m venv venv
    if [ $? -ne 0 ]; then
        echo "Failed to create virtual environment!"
        exit 1
    fi
    echo "Virtual environment created successfully."
else
    echo "Virtual environment already exists."
fi

# Check the directory structure of venv and attempt to activate
if [ -f "venv/bin/activate" ]; then
    source venv/bin/activate
    echo "Virtual environment activated."
else
    echo "Failed to locate virtual environment activation script in venv/bin/activate."
    exit 1
fi

# Install Python dependencies
echo "Installing Python dependencies within virtual environment..."
pip install google-cloud-pubsub google-api-python-client

echo "All dependencies installed successfully within the virtual environment."
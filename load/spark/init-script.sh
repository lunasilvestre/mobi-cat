#!/bin/bash

# Install pip if it is not already installed
if ! command -v pip &>/dev/null; then
    apt-get update
    apt-get install -y python3-pip
fi

# Install Python packages from requirements.txt
pip install -r gs://<your-bucket>/path-to-your-spark-job/requirements.txt
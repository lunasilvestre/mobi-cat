#!/bin/bash

# Check if the .env file exists
if [ -f .env ]; then
  echo ".env file already exists. Skipping setup."
else
  # Copy the .env.sample file to .env
  cp .env.sample .env

  # Ask the developer to fill in the values
  echo "Please fill in the values in the .env file."
  echo "For more information, see the .env.sample file."
fi

# Load the .env file
if [ -f .env ]; then
  # Load environment variables from the .env file
  export $(grep -v '^#' .env | xargs)
else
  echo ".env file not found!"
fi

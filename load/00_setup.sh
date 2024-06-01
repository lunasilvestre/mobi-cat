#!/bin/bash

# Check if the .env file exists
if [ -f .env ]; then
  echo ".env file already exists."
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

  # Loop through each line in the .env file
  while IFS= read -r line || [ -n "$line" ]; do
    # Skip empty lines and comments
    if [[ ! -z "$line" && "$line" != \#* ]]; then
      # Extract the key and value
      key=$(echo "$line" | cut -d '=' -f1)
      value=$(echo "$line" | cut -d '=' -f2-)

      # Export the variable
      export "$key"="$value"

      # Debug output to verify
      #echo "$key=${!key}"
    fi
  done < .env
  echo "Environment variables loaded successfully."
else
  echo ".env file not found!"
fi

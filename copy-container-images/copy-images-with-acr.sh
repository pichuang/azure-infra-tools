#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Check if Azure CLI is installed
if ! command -v az &> /dev/null; then
    echo "Error: Azure CLI command not found. Please install Azure CLI first."
    echo "On macOS, you can use: brew install azure-cli"
    echo "On Ubuntu, you can use: apt-get install azure-cli"
    exit 1
fi

# Check parameters
if [ $# -lt 2 ]; then
    echo "Usage: $0 <images-list-file> <dest-registry> [dest-username] [dest-password]"
    echo "Example: $0 ./images-list pichuang.azurecr.io pichuang \"password123\""
    exit 1
fi

IMAGES_LIST="$1"
DEST_REGISTRY="$2"

# Optional parameters: credentials for destination registry
DEST_USERNAME="${3:-}"
DEST_PASSWORD="${4:-}"

# Set authentication arguments (if credentials are provided)
AUTH_ARGS=""
if [ -n "$DEST_USERNAME" ] && [ -n "$DEST_PASSWORD" ]; then
    echo "Using provided credentials for authentication..."
    AUTH_ARGS="--username $DEST_USERNAME --password $DEST_PASSWORD"
fi

# Prompt for subscription ID if ACR not found
if ! az acr show --name $DEST_REGISTRY &> /dev/null; then
    echo "ACR not found in the current subscription. Please enter the subscription ID where the ACR is located:"
    read SUBSCRIPTION_ID
    az account set --subscription "$SUBSCRIPTION_ID"
    if ! az acr show --name $DEST_REGISTRY &> /dev/null; then
        echo "Error: ACR still not found in the specified subscription. Please check the ACR name and subscription ID."
        exit 1
    fi
fi

# Read the image list and import each image
echo "Starting to import container images to $DEST_REGISTRY..."

# Create a temporary file to store the list of images
TEMP_IMAGES_LIST=$(mktemp)
cat "$IMAGES_LIST" | grep -v "^#" | grep -v "^$" > "$TEMP_IMAGES_LIST"

# Count total images
TOTAL_IMAGES=$(wc -l < "$TEMP_IMAGES_LIST")
echo "Total container images to import: $TOTAL_IMAGES"

# Process images sequentially
COMPLETED=0

while read IMAGE; do
    # Skip comment lines and empty lines
    if [[ "$IMAGE" =~ ^# ]] || [[ -z "$IMAGE" ]]; then
        continue
    fi

    # Extract the repository and tag from the image
    REPO_AND_TAG=$(echo "$IMAGE" | awk -F'/' '{print $NF}')
    REPOSITORY=$(echo "$REPO_AND_TAG" | cut -d':' -f1)
    TAG=$(echo "$REPO_AND_TAG" | cut -d':' -f2)

    echo "Importing $IMAGE to $DEST_REGISTRY..."
    az acr import --name $DEST_REGISTRY --source $IMAGE $AUTH_ARGS --force --only-show-errors
    if [ $? -eq 0 ]; then
        echo "Successfully imported $IMAGE"
        COMPLETED=$((COMPLETED + 1))
        echo "Progress: $COMPLETED/$TOTAL_IMAGES"
    else
        echo "Failed to import $IMAGE"
    fi
done < "$TEMP_IMAGES_LIST"

# Clean up
echo "Cleaning up..."
rm "$TEMP_IMAGES_LIST"

echo "Completed importing $COMPLETED out of $TOTAL_IMAGES images."

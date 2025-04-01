#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Check if skopeo is installed
if ! command -v skopeo &> /dev/null; then
    echo "Error: skopeo command not found. Please install skopeo first."
    echo "On macOS, you can use: brew install skopeo"
    echo "On Ubuntu, you can use: apt-get install skopeo"
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
    AUTH_ARGS="--dest-creds $DEST_USERNAME:$DEST_PASSWORD"
fi

# Read the image list and copy each image
echo "Starting to copy container images to $DEST_REGISTRY..."

# Create a temporary file to store the list of images
TEMP_IMAGES_LIST=$(mktemp)
cat "$IMAGES_LIST" | grep -v "^#" | grep -v "^$" > "$TEMP_IMAGES_LIST"

# Count total images
TOTAL_IMAGES=$(wc -l < "$TEMP_IMAGES_LIST")
echo "Total container images to copy: $TOTAL_IMAGES"

# Process images sequentially
COMPLETED=0

while read IMAGE; do
    # Skip comment lines and empty lines
    if [[ "$IMAGE" =~ ^# ]] || [[ -z "$IMAGE" ]]; then
        continue
    fi

    # Parse image name and tag
    SOURCE_IMAGE="$IMAGE"

    # Extract image path (excluding registry)
    IMAGE_PATH=$(echo "$SOURCE_IMAGE" | sed 's|^[^/]*/||')

    # Build destination image URL
    DEST_IMAGE="$DEST_REGISTRY/$IMAGE_PATH"

    echo "Copying: $SOURCE_IMAGE -> $DEST_IMAGE"

    # Use skopeo to copy the image
    skopeo copy docker://$SOURCE_IMAGE docker://$DEST_IMAGE $AUTH_ARGS

    COMPLETED=$((COMPLETED + 1))
    echo "Progress: $COMPLETED/$TOTAL_IMAGES"
done < "$TEMP_IMAGES_LIST"

# Clean up
rm -f "$TEMP_IMAGES_LIST"

echo "All container images have been successfully copied to $DEST_REGISTRY"

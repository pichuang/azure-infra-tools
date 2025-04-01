# Azure Container Image Import Script

This script facilitates importing container images from other container registries into Azure Container Registry.

## Features

- Import images from a source container registry to Azure Container Registry
- Supports authentication with username and password
- Automatically skips comments and empty lines in the image list file
- Checks for Azure CLI installation before execution

## Prerequisites

- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli) must be installed
- On macOS: `brew install azure-cli`
- On Ubuntu: `apt-get install azure-cli`

## Usage

```bash
./import-to-acr.sh <images-list-file> <dest-registry> [dest-username] [dest-password]
```

### Parameters

- `images-list-file`: Path to a file containing a list of container images to import
- `dest-registry`: Destination registry URL (e.g., `pichuang.azurecr.io`)
- `dest-username` (optional): Username for destination registry authentication
- `dest-password` (optional): Password for destination registry authentication

### Example

```bash
./import-to-acr.sh ./images-list pichuang.azurecr.io pichuang "password123"
```

## Image List Format

The image list file should contain one image per line. Lines starting with `#` are treated as comments and will be ignored. Empty lines are also ignored.

Example `images-list` file:

```
# Studio
mcr.microsoft.com/azure-cognitive-services/form-recognizer/studio:3.0
mcr.microsoft.com/azure-cognitive-services/form-recognizer/studio:3.1
mcr.microsoft.com/azure-cognitive-services/form-recognizer/studio:latest
```

## How It Works

1. The script reads the image list file line by line
2. For each image, it extracts the path (excluding the registry)
3. It then constructs the destination image URL by combining the destination registry with the extracted path
4. Finally, it uses Azure CLI to import the image from the source registry to the destination registry

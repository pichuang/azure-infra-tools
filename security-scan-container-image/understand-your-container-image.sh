#!/bin/bash
IMAGE=mcr.microsoft.com/azure-cognitive-services/diagnostic:latest
REPORT_NAME=trivy-scan.json

# Download the specified container image
docker pull ${IMAGE}

# Generate a report for the specified container image
trivy image \
  --pkg-types os,library \
  --format json \
  --quiet \
  --output ${REPORT_NAME} \
  ${IMAGE}

# Show result summary
jq '
  [ ..
    | .Vulnerabilities?
    | .[]?
  ] as $all |
  {
    "Total number of vulnerabilities":        ($all | length),
    "Number of fixable vulnerabilities":  ($all | map(select(.FixedVersion != null and .FixedVersion != "")) | length),
    "Number of non-fixable vulnerabilities":($all | map(select(.FixedVersion == null or .FixedVersion == "")) | length)
  }
' ${REPORT_NAME}
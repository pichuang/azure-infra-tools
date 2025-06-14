#!/bin/bash
IMAGE=mcr.microsoft.com/azurelinux/base/nginx:1.25.4-2-azl3.0.20250102
REPORT_NAME=azurelinux-base-nginx.json
PATCHED_IMAGE=${IMAGE}-patched
PATCHED_REPORT_NAME=${REPORT_NAME}.patched

#
# Before running this script, ensure you have:
#
docker pull ${IMAGE}

# Generate a report for the specified image
trivy image \
  --pkg-types os,library \
  --format json \
  --quiet \
  --output ${REPORT_NAME} \
  ${IMAGE}

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

echo "=========================================================="

#
# Patch by Copa
#
copa patch \
    --report ${REPORT_NAME} \
    --image ${IMAGE}

echo "=========================================================="

#
# Rescan by trivy
#
# Generate a report for the specified image
trivy image \
  --pkg-types os,library \
  --format json \
  --quiet \
  --output ${PATCHED_REPORT_NAME} \
  ${PATCHED_IMAGE}

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
' ${PATCHED_REPORT_NAME}
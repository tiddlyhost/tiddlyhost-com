#!/bin/bash
set -euo pipefail

IMAGE_REF=$1
DOCKER_FILE=$2
MESSAGE=${3:-""}

NO_COMMIT=${NO_COMMIT:-""}

IMAGE_DIGEST="$(skopeo inspect --no-tags docker://${IMAGE_REF} --format '{{.Digest}}')"

REQUIRED="FROM ${IMAGE_REF}@${IMAGE_DIGEST}"
CURRENT=$( grep -E "^FROM ${IMAGE_REF}" "${DOCKER_FILE}" )

if [[ "$REQUIRED" == "$CURRENT" ]]; then
  echo "${CURRENT} is correct for $IMAGE_REF"
else
  echo "Updating ${CURRENT} to ${REQUIRED}"
  sed -i "s|${CURRENT}|${REQUIRED}|" "${DOCKER_FILE}"
  git add "${DOCKER_FILE}"
  if [[ -z "$NO_COMMIT" ]]; then
    git commit "${DOCKER_FILE}" -m "chore: Bump ${IMAGE_REF/:latest/} digest" -m "Commit created with bin/pin-digest.sh" -m "$MESSAGE"
  fi
fi

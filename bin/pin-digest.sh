#!/bin/bash
set -euo pipefail

IMAGE_REF=$1
DOCKER_FILE=$2
MESSAGE=${3:-""}

IMAGE_DIGEST="$( docker image inspect ${IMAGE_REF} --format '{{index .RepoDigests 0}}' | cut -d'@' -f2 )"

REQUIRED="FROM ${IMAGE_REF}@${IMAGE_DIGEST}"
CURRENT=$( grep -E "^FROM ${IMAGE_REF}" "${DOCKER_FILE}" )

if [[ "$REQUIRED" == "$CURRENT" ]]; then
  echo "${CURRENT} is correct for $IMAGE_REF"
else
  echo "Updating ${CURRENT} to ${REQUIRED}"
  sed -i "s|${CURRENT}|${REQUIRED}|" "${DOCKER_FILE}"
  git commit "${DOCKER_FILE}" -m "chore: Bump ${IMAGE_REF/:latest/} digest" -m "Commit created with bin/pin-digest.sh" -m "$MESSAGE"
fi

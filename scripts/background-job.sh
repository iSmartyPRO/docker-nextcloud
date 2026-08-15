#!/usr/bin/env bash
source "$(dirname "$0")/lib/common.sh"
docker exec -u 33 "$DOCKER_CONTAINER_NAME" php occ config:system:set maintenance_window_start --type=integer --value=1

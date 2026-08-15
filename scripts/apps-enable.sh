#!/usr/bin/env bash
source "$(dirname "$0")/lib/common.sh"

docker exec -u 33 "$DOCKER_CONTAINER_NAME" php occ app:install user_ldap || true
docker exec -u 33 "$DOCKER_CONTAINER_NAME" php occ app:enable user_ldap
docker exec -u 33 "$DOCKER_CONTAINER_NAME" php occ app:install files_external || true
docker exec -u 33 "$DOCKER_CONTAINER_NAME" php occ app:enable files_external

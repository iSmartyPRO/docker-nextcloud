#!/usr/bin/env bash
source "$(dirname "$0")/lib/common.sh"

mkdir -p ./files/skeleton
rm -rf ./files/core/skeleton/* || true

docker exec -u 33 "$DOCKER_CONTAINER_NAME" php occ config:system:set skeletondirectory --type=string --value="/var/www/html/skeleton"
docker exec -u 33 "$DOCKER_CONTAINER_NAME" php occ config:system:set overwriteprotocol --type=string --value="https"
docker exec -u 33 "$DOCKER_CONTAINER_NAME" php occ config:system:set default_phone_region --type=string --value="RU"
docker exec -u 33 "$DOCKER_CONTAINER_NAME" php occ config:system:set quota_default --type=string --value="1 GB"
docker exec -u 33 "$DOCKER_CONTAINER_NAME" php occ config:app:set files default_quota --value="1 GB"
docker exec -u 33 "$DOCKER_CONTAINER_NAME" php occ config:system:set defaultapp --value="files"
docker exec -u 33 "$DOCKER_CONTAINER_NAME" php occ config:app:set core defaultapp --value="files"
docker exec -u 33 "$DOCKER_CONTAINER_NAME" php occ config:system:set maintenance_window_start --type=integer --value=1
docker exec -u 33 "$DOCKER_CONTAINER_NAME" php occ config:system:set mail_smtps --type=string --value="$MAIL_SMTPS"
docker exec -u 33 "$DOCKER_CONTAINER_NAME" php occ config:system:set mail_port --type=integer --value="$MAIL_PORT"
docker exec -u 33 "$DOCKER_CONTAINER_NAME" php occ config:system:set mail_from_address --type=string --value="$MAIL_FROM_ADDRESS"
docker exec -u 33 "$DOCKER_CONTAINER_NAME" php occ config:system:set mail_domain --type=string --value="$MAIL_DOMAIN"
docker exec -u 33 "$DOCKER_CONTAINER_NAME" php occ config:system:set mail_auth_modes --type=string --value="$MAIL_AUTH_MODES"
docker exec -u 33 "$DOCKER_CONTAINER_NAME" php occ config:system:set mail_user --type=string --value="$MAIL_USER"
docker exec -u 33 "$DOCKER_CONTAINER_NAME" php occ config:system:set mail_password --type=string --value="$MAIL_PASSWORD"
docker exec -u 33 "$DOCKER_CONTAINER_NAME" php occ maintenance:repair --include-expensive
docker exec -u 33 "$DOCKER_CONTAINER_NAME" php occ db:convert-filecache-bigint
docker exec -u 33 "$DOCKER_CONTAINER_NAME" php occ db:add-missing-indices

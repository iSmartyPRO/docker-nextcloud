#!/usr/bin/env bash
source "$(dirname "$0")/lib/common.sh"

docker exec -u 33 "$DOCKER_CONTAINER_NAME" php occ theming:config name "${THEMING_NAME:-}"
docker exec -u 33 "$DOCKER_CONTAINER_NAME" php occ theming:config slogan "$THEMING_SLOGAN"
docker exec -u 33 "$DOCKER_CONTAINER_NAME" php occ theming:config url "$THEMING_URL"
docker exec -u 33 "$DOCKER_CONTAINER_NAME" php occ theming:config primary_color "$THEMING_PRIMARYCOLOR"

mkdir -p ./files/themes
cp ./theming/logo.svg ./files/themes/
docker exec -u 33 "$DOCKER_CONTAINER_NAME" php occ theming:config logo /var/www/html/themes/logo.svg
docker exec -u 33 "$DOCKER_CONTAINER_NAME" php occ theming:config logoheader /var/www/html/themes/logo.svg

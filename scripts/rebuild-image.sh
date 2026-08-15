#!/usr/bin/env bash
source "$(dirname "$0")/lib/common.sh"

# Пересборка образа Nextcloud (SMB и LibreDWG вшиты в Dockerfile).
# Нужна после смены базового nextcloud:latest.
docker compose build nextcloud
docker compose up -d nextcloud
docker exec "$DOCKER_CONTAINER_NAME" php -m | grep -i smb
docker exec "$DOCKER_CONTAINER_NAME" smbclient -V
docker exec "$DOCKER_CONTAINER_NAME" sh -c 'command -v dwg2SVG || command -v dwg2svg'
docker exec "$DOCKER_CONTAINER_NAME" rsvg-convert --version | head -n1

#!/usr/bin/env bash
source "$(dirname "$0")/lib/common.sh"

if [[ -z "${COLLABORA_URL:-}" || -z "${NEXTCLOUD_URL:-}" ]]; then
  echo "В .env задайте COLLABORA_URL и NEXTCLOUD_URL" >&2
  exit 1
fi

OO_CONTAINER="${DOCKER_CONTAINER_NAME}_collabora"

echo "Ожидание готовности Collabora (${OO_CONTAINER})..."
for i in $(seq 1 60); do
  if curl -fsS -m 3 "http://127.0.0.1:${COLLABORA_PORT:-9980}/hosting/discovery" >/dev/null 2>&1; then
    echo "Collabora готов."
    break
  fi
  if [[ "$i" -eq 60 ]]; then
    echo "Collabora не ответил за отведённое время." >&2
    docker logs --tail 40 "$OO_CONTAINER" || true
    exit 1
  fi
  sleep 5
done

docker exec -u 33 "$DOCKER_CONTAINER_NAME" php occ app:install richdocuments || true
docker exec -u 33 "$DOCKER_CONTAINER_NAME" php occ app:enable richdocuments
docker exec -u 33 "$DOCKER_CONTAINER_NAME" php occ config:app:set richdocuments wopi_url --value="${COLLABORA_URL%/}"
docker exec -u 33 "$DOCKER_CONTAINER_NAME" php occ config:app:set richdocuments public_wopi_url --value="${COLLABORA_URL%/}"
docker exec -u 33 "$DOCKER_CONTAINER_NAME" php occ config:app:set richdocuments disable_certificate_verification --value="no"
docker exec -u 33 "$DOCKER_CONTAINER_NAME" php occ config:system:set allow_local_remote_servers --type=boolean --value=true
docker exec -u 33 "$DOCKER_CONTAINER_NAME" php occ richdocuments:activate-config

echo
echo "Collabora настроен:"
echo "  wopi_url        = ${COLLABORA_URL%/}"
echo "  public_wopi_url = ${COLLABORA_URL%/}"

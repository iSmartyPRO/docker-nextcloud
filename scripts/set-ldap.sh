#!/usr/bin/env bash
source "$(dirname "$0")/lib/common.sh"

if [[ -z "${LDAP_HOST:-}" || -z "${LDAP_PORT:-}" || -z "${LDAP_BASE:-}" || -z "${LDAP_AGENTNAME:-}" || -z "${LDAP_AGENTPASSWORD:-}" ]]; then
  echo "В .env задайте LDAP_HOST, LDAP_PORT, LDAP_BASE, LDAP_AGENTNAME, LDAP_AGENTPASSWORD" >&2
  exit 1
fi

echo "LDAP_HOST=$LDAP_HOST"
echo "LDAP_PORT=$LDAP_PORT"
echo "LDAP_BASE=$LDAP_BASE"
echo "LDAP_AGENTNAME=$LDAP_AGENTNAME"

docker exec -u 33 "$DOCKER_CONTAINER_NAME" php occ app:enable user_ldap
docker exec -u 33 "$DOCKER_CONTAINER_NAME" php occ ldap:set-config s01 ldapHost "$LDAP_HOST"
docker exec -u 33 "$DOCKER_CONTAINER_NAME" php occ ldap:set-config s01 ldapPort "$LDAP_PORT"
docker exec -u 33 "$DOCKER_CONTAINER_NAME" php occ ldap:set-config s01 ldapBase "$LDAP_BASE"
docker exec -u 33 "$DOCKER_CONTAINER_NAME" php occ ldap:set-config s01 ldapAgentName "$LDAP_AGENTNAME"
docker exec -u 33 "$DOCKER_CONTAINER_NAME" php occ ldap:set-config s01 ldapAgentPassword "$LDAP_AGENTPASSWORD"
docker exec -u 33 "$DOCKER_CONTAINER_NAME" php occ ldap:set-config s01 ldapLoginFilter "(&(objectClass=person)(uid=%uid))"
docker exec -u 33 "$DOCKER_CONTAINER_NAME" php occ ldap:test-config s01

echo "LDAP-конфигурация применена."

#!/bin/bash

while read -r LINE; do
if [[ $LINE == *'='* ]] && [[ $LINE != '#'* ]]; then
    ENV_VAR="$(echo $LINE | envsubst)"
    eval "declare $ENV_VAR"
fi
done < .env

#docker exec -u 33 $DOCKER_CONTAINER_NAME php occ app:enable user_ldap
docker exec -u 33 $DOCKER_CONTAINER_NAME php occ ldap:set-config s01 ldapHost $LDAP_HOST
docker exec -u 33 $DOCKER_CONTAINER_NAME php occ ldap:set-config s01 ldapPort $LDAP_PORT
docker exec -u 33 $DOCKER_CONTAINER_NAME php occ ldap:set-config s01 ldapBase $LDAP_BASE
docker exec -u 33 $DOCKER_CONTAINER_NAME php occ ldap:set-config s01 ldapAgentName "$LDAP_AGENTNAME"
docker exec -u 33 $DOCKER_CONTAINER_NAME php occ ldap:set-config s01 ldapAgentPassword "$LDAP_AGENTPASSWORD"
docker exec -u 33 $DOCKER_CONTAINER_NAME php occ ldap:set-config s01 ldapLoginFilterAttributes sAMAccountName
docker exec -u 33 $DOCKER_CONTAINER_NAME php occ ldap:test-config s01

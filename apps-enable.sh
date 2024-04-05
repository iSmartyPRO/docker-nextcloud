#!/bin/bash

while read -r LINE; do
if [[ $LINE == *'='* ]] && [[ $LINE != '#'* ]]; then
    ENV_VAR="$(echo $LINE | envsubst)"
    eval "declare $ENV_VAR"
fi
done < .env

docker exec -u 33 $DOCKER_CONTAINER_NAME php occ app:instal user_ldap
docker exec -u 33 $DOCKER_CONTAINER_NAME php occ app:enable user_ldap
docker exec -u 33 $DOCKER_CONTAINER_NAME php occ app:instal files_external
docker exec -u 33 $DOCKER_CONTAINER_NAME php occ app:enable files_external
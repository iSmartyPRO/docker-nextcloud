#!/bin/bash

while read -r LINE; do
if [[ $LINE == *'='* ]] && [[ $LINE != '#'* ]]; then
    ENV_VAR="$(echo $LINE | envsubst)"
    eval "declare $ENV_VAR"
fi
done < .env

docker exec -u 33 $DOCKER_CONTAINER_NAME php occ config:system:set maintenance_window_start --type=integer --value=1
#!/bin/bash

while read -r LINE; do
if [[ $LINE == *'='* ]] && [[ $LINE != '#'* ]]; then
    ENV_VAR="$(echo $LINE | envsubst)"
    eval "declare $ENV_VAR"
fi
done < .env

mkdir ./files/skeleton
docker exec -u 33 $DOCKER_CONTAINER_NAME php occ config:app:set core defaultTemplateDirectory --value="/var/www/html/html"
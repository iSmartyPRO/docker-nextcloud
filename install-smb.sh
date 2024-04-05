#!/bin/bash

while read -r LINE; do
if [[ $LINE == *'='* ]] && [[ $LINE != '#'* ]]; then
    ENV_VAR="$(echo $LINE | envsubst)"
    eval "declare $ENV_VAR"
fi
done < .env

docker exec $DOCKER_CONTAINER_NAME apt update
docker exec -ti $DOCKER_CONTAINER_NAME apt install smbclient libsmbclient-dev
docker exec -ti $DOCKER_CONTAINER_NAME pecl install smbclient
docker exec -ti $DOCKER_CONTAINER_NAME docker-php-ext-enable smbclient
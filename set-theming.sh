#!/bin/bash

while read -r LINE; do
if [[ $LINE == *'='* ]] && [[ $LINE != '#'* ]]; then
    ENV_VAR="$(echo $LINE | envsubst)"
    eval "declare $ENV_VAR"
fi
done < .env

docker exec -u 33 $DOCKER_CONTAINER_NAME php occ theming:config name "$THEMING_NAME"
docker exec -u 33 $DOCKER_CONTAINER_NAME php occ theming:config slogan "$THEMING_SLOGAN"
docker exec -u 33 $DOCKER_CONTAINER_NAME php occ theming:config url $THEMING_URL
docker exec -u 33 $DOCKER_CONTAINER_NAME php occ theming:config primary_color $THEMING_PRIMARYCOLOR

cp ./theming/logo.svg ./files/themes/
docker exec -u 33 $DOCKER_CONTAINER_NAME php occ theming:config logo /var/www/html/themes/logo.svg
docker exec -u 33 $DOCKER_CONTAINER_NAME php occ theming:config logoheader /var/www/html/themes/logo.svg

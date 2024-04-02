#!/bin/bash

while read -r LINE; do
if [[ $LINE == *'='* ]] && [[ $LINE != '#'* ]]; then
    ENV_VAR="$(echo $LINE | envsubst)"
    eval "declare $ENV_VAR"
fi
done < .env

docker exec -u 33 $DOCKER_CONTAINER_NAME php occ app:disable password_policy
docker exec -u 33 $DOCKER_CONTAINER_NAME php occ app:disable federatedfilesharing
docker exec -u 33 $DOCKER_CONTAINER_NAME php occ app:disable cloud_federation_api
docker exec -u 33 $DOCKER_CONTAINER_NAME php occ app:disable activity
docker exec -u 33 $DOCKER_CONTAINER_NAME php occ app:disable circles
docker exec -u 33 $DOCKER_CONTAINER_NAME php occ app:disable comments
docker exec -u 33 $DOCKER_CONTAINER_NAME php occ app:disable contactsinteraction
docker exec -u 33 $DOCKER_CONTAINER_NAME php occ app:disable dashboard
docker exec -u 33 $DOCKER_CONTAINER_NAME php occ app:disable federation
docker exec -u 33 $DOCKER_CONTAINER_NAME php occ app:disable files_reminders
docker exec -u 33 $DOCKER_CONTAINER_NAME php occ app:disable files_trashbin
docker exec -u 33 $DOCKER_CONTAINER_NAME php occ app:disable files_versions
docker exec -u 33 $DOCKER_CONTAINER_NAME php occ app:disable firstrunwizard
docker exec -u 33 $DOCKER_CONTAINER_NAME php occ app:disable logreader
docker exec -u 33 $DOCKER_CONTAINER_NAME php occ app:disable lookup_server_connector
docker exec -u 33 $DOCKER_CONTAINER_NAME php occ app:disable nextcloud_announcements
docker exec -u 33 $DOCKER_CONTAINER_NAME php occ app:disable notifications
docker exec -u 33 $DOCKER_CONTAINER_NAME php occ app:disable privacy
docker exec -u 33 $DOCKER_CONTAINER_NAME php occ app:disable provisioning_api
docker exec -u 33 $DOCKER_CONTAINER_NAME php occ app:disable recommendations
docker exec -u 33 $DOCKER_CONTAINER_NAME php occ app:disable related_resources
docker exec -u 33 $DOCKER_CONTAINER_NAME php occ app:disable sharebymail
docker exec -u 33 $DOCKER_CONTAINER_NAME php occ app:disable support
docker exec -u 33 $DOCKER_CONTAINER_NAME php occ app:disable survey_client
docker exec -u 33 $DOCKER_CONTAINER_NAME php occ app:disable systemtags
docker exec -u 33 $DOCKER_CONTAINER_NAME php occ app:disable user_status
docker exec -u 33 $DOCKER_CONTAINER_NAME php occ app:disable weather_status
docker exec -u 33 $DOCKER_CONTAINER_NAME php occ app:disable workflowengine
docker exec -u 33 $DOCKER_CONTAINER_NAME php occ app:disable updatenotification
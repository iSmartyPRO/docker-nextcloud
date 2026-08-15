#!/usr/bin/env bash
source "$(dirname "$0")/lib/common.sh"

apps=(
  password_policy
  federatedfilesharing
  cloud_federation_api
  activity
  circles
  comments
  contactsinteraction
  dashboard
  federation
  files_reminders
  files_trashbin
  files_versions
  firstrunwizard
  logreader
  lookup_server_connector
  nextcloud_announcements
  notifications
  privacy
  provisioning_api
  recommendations
  related_resources
  sharebymail
  support
  survey_client
  systemtags
  user_status
  weather_status
  workflowengine
  updatenotification
)

for app in "${apps[@]}"; do
  docker exec -u 33 "$DOCKER_CONTAINER_NAME" php occ app:disable "$app" || true
done

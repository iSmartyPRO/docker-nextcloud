#!/bin/bash

# Проверяем, существует ли файл .env
if [ ! -f .env ]; then
  echo "Файл .env не найден!"
  exit 1
fi

# Загружаем переменные окружения из .env
source .env

# Проверяем переменные окружения
echo "LDAP_HOST=$LDAP_HOST"
echo "LDAP_PORT=$LDAP_PORT"
echo "LDAP_BASE=$LDAP_BASE"
echo "LDAP_AGENTNAME=$LDAP_AGENTNAME"
echo "LDAP_AGENTPASSWORD=$LDAP_AGENTPASSWORD"

# Проверяем, все ли переменные заданы
if [ -z "$LDAP_HOST" ] || [ -z "$LDAP_PORT" ] || [ -z "$LDAP_BASE" ] || [ -z "$LDAP_AGENTNAME" ] || [ -z "$LDAP_AGENTPASSWORD" ]; then
  echo "Одна или несколько переменных не заданы в файле .env!"
  exit 1
fi

# Устанавливаем конфигурацию LDAP с корректным фильтром
docker exec -u 33 "$DOCKER_CONTAINER_NAME" php occ app:enable user_ldap
# docker exec -u 33 "$DOCKER_CONTAINER_NAME" php occ ldap:create-empty-config
docker exec -u 33 "$DOCKER_CONTAINER_NAME" php occ ldap:set-config s01 ldapHost "$LDAP_HOST"
docker exec -u 33 "$DOCKER_CONTAINER_NAME" php occ ldap:set-config s01 ldapPort "$LDAP_PORT"
docker exec -u 33 "$DOCKER_CONTAINER_NAME" php occ ldap:set-config s01 ldapBase "$LDAP_BASE"
docker exec -u 33 "$DOCKER_CONTAINER_NAME" php occ ldap:set-config s01 ldapAgentName "$LDAP_AGENTNAME"
docker exec -u 33 "$DOCKER_CONTAINER_NAME" php occ ldap:set-config s01 ldapAgentPassword "$LDAP_AGENTPASSWORD"
docker exec -u 33 "$DOCKER_CONTAINER_NAME" php occ ldap:set-config s01 ldapLoginFilter "(&(objectClass=person)(uid=%uid))"
docker exec -u 33 "$DOCKER_CONTAINER_NAME" php occ ldap:test-config s01

if [ $? -eq 0 ]; then
  echo "LDAP конфигурация установлена корректно."
else
  echo "Ошибка при установке LDAP конфигурации."
  exit 1
fi

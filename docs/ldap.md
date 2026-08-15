# LDAP / Active Directory

## Применение

Заполните в `.env` блок `LDAP_*`, затем:

```bash
./scripts/set-ldap.sh
```

Проверка без изменения настроек:

```bash
./scripts/test-ldap.sh
```

Фильтр входа по умолчанию:

```
(&(objectClass=person)(uid=%uid))
```

При необходимости поправьте его через `occ ldap:set-config` или в админке Nextcloud.

## Полезные команды

```bash
docker exec -u 33 "$DOCKER_CONTAINER_NAME" php occ ldap:show-config
docker exec -u 33 "$DOCKER_CONTAINER_NAME" php occ ldap:test-config s01
docker exec -u 33 "$DOCKER_CONTAINER_NAME" php occ user:report
```

Контейнер должен резолвить контроллер домена (`LDAP_HOST`) из `docker-lan` или через DNS хоста.

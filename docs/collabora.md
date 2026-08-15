# Collabora Online

Редактор документов (CODE) в контейнере `${DOCKER_CONTAINER_NAME}_collabora`. OnlyOffice в стеке больше нет.

## Запуск

1. Заполните `COLLABORA_*` и `NEXTCLOUD_URL` в `.env`.
2. `COLLABORA_WOPI_HOST` — hostname облака без схемы, например `cloud.example.com`.
3. Поднимите сервис: `docker compose up -d collabora`.
4. Настройте nginx (см. [nginx.md](nginx.md)).
5. Привяжите к Nextcloud:

```bash
./scripts/set-collabora.sh
```

Проверка:

```bash
curl -sk https://collabora.example.com/hosting/capabilities
docker exec -u 33 "$DOCKER_CONTAINER_NAME" php occ richdocuments:activate-config
```

## Jail patch

Образ CODE в Docker падает на self-test mount. Файлы в `collabora/` монтируются в контейнер (см. `collabora/README.md`).

После обновления образа Collabora:

```bash
./collabora/apply-caps.sh
docker compose up -d collabora
```

## Ресурсы

Лимит контейнера — 2 GiB RAM, swap отключён. На 2–4 одновременных документа этого достаточно. При упоре в лимит пострадает только Collabora, не весь хост.

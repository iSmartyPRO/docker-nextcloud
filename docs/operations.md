# Эксплуатация

Все скрипты читают `.env` из корня репозитория. Запускайте их из любой директории:

```bash
./scripts/apps-list.sh
```

## occ

```bash
docker exec -u 33 "$DOCKER_CONTAINER_NAME" php occ list
docker exec -u 33 "$DOCKER_CONTAINER_NAME" php occ status
docker exec -u 33 "$DOCKER_CONTAINER_NAME" php occ user:report
```

Пользователь `www-data` в контейнере — UID 33.

## Приложения

```bash
./scripts/apps-list.sh
./scripts/apps-enable.sh    # LDAP + files_external
./scripts/set-cad.sh        # DWG/DXF просмотр и превью
./scripts/apps-disable.sh   # выключить лишние штатные приложения
./scripts/background-job.sh # окно фоновых задач
```

Пошаговое обновление с бэкапом и миграциями схемы: [deploy.md](deploy.md) (сценарий B).

## Обновление Nextcloud

```bash
docker compose pull redis collabora
./scripts/rebuild-image.sh
docker exec -u 33 "$DOCKER_CONTAINER_NAME" php occ upgrade
docker exec -u 33 "$DOCKER_CONTAINER_NAME" php occ db:add-missing-indices
```

`rebuild-image.sh` пересобирает `cloud-nextcloud:local` от актуального `nextcloud:latest` и сохраняет SMB и LibreDWG.

После `occ upgrade` ядро перезаписывает `files/core/` (иконки DWG и `mimetypelist.js`). Сразу:

```bash
./scripts/set-cad.sh
```

Иначе `.dwg` снова станет серым файлом с диалогом сохранения. Подробности: [cad.md](cad.md).

## Обновление Collabora

```bash
docker compose pull collabora
./collabora/apply-caps.sh
docker compose up -d collabora
./scripts/set-collabora.sh
```

## Бэкап

Нужны три вещи:

1. Каталог `./files` (код, `config.php`, `data/`)
2. Дамп PostgreSQL базы из `POSTGRES_DB`
3. `.env` (хранить отдельно, не в git)

```bash
set -a && source .env && set +a
mkdir -p backups
docker exec "$POSTGRES_HOST" pg_dump -U "$POSTGRES_USER" "$POSTGRES_DB" \
  | gzip > "backups/${POSTGRES_DB}-$(date +%F).sql.gz"
```

Каталог `backups/` в git не входит.

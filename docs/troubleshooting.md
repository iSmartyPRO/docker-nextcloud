# Устранение неполадок

## Не логинится с первого раза

Ошибка CSP `form-action 'self'`. Выставьте `overwriteprotocol=https` (`./scripts/set-basics.sh`) и проверьте, что nginx передаёт `X-Forwarded-Proto`.

## SMB-шара пустая или «storage not available»

1. В контейнере должны быть модули: `docker exec $DOCKER_CONTAINER_NAME php -m | grep smb`
2. Если их нет — образ собрали не из `Dockerfile`. Запустите `./scripts/rebuild-image.sh`
3. Для шары с логином пользователя проверка из CLI не сработает — войдите в веб

## Collabora не открывает документ

- `curl -sk https://collabora.example.com/hosting/discovery` должен вернуть XML
- `occ richdocuments:activate-config` без ошибок
- В `.env` `COLLABORA_WOPI_HOST` совпадает с hostname облака
- nginx проксирует `/browser`, `/cool`, `/hosting` с WebSocket
- После смены образа Collabora: `./collabora/apply-caps.sh`
- Если вместо Collabora открылся File Viewer — `occ files_cad:configure-fileviewer`

## Nextcloud в maintenance

```bash
docker exec -u 33 "$DOCKER_CONTAINER_NAME" php occ maintenance:mode --off
```

## DWG: окно «Сохранить файл» или серая иконка

Это не «файл битый». Ядро Nextcloud не знает `.dwg`, пока не выполнен CAD-деплой. Полный разбор: [cad.md](cad.md).

Быстрая проверка (подставить имя контейнера из `.env`):

```bash
set -a && source .env && set +a
docker exec "$DOCKER_CONTAINER_NAME" test -f /var/www/html/custom_apps/files_cad/appinfo/info.xml && echo app_mounted
docker exec -u 33 "$DOCKER_CONTAINER_NAME" php occ app:list | grep -E 'files_cad|fileviewer'
docker exec "$DOCKER_CONTAINER_NAME" test -f /var/www/html/core/img/filetypes/application-dwg.svg && echo icon_ok
```

| Симптом | Что сделать |
|---|---|
| `app_mounted` нет | `docker compose up -d nextcloud` — том `./apps/files_cad` не подключён |
| Нет `files_cad` / `fileviewer` в app:list | `./scripts/set-cad.sh` |
| Иконка серая после скрипта | Ctrl+F5; снова `occ maintenance:mimetype:update-js` |
| Клик всё ещё «Сохранить» | `occ maintenance:mimetype:update-db --repair-filecache` — старые файлы (и SMB) остались `octet-stream` |
| docx открылся не в Collabora | `occ files_cad:configure-fileviewer` |
| Нет `dwg2SVG`, но чертёж открывается | Так и должно быть. Конвертер только для миниатюр: `./scripts/rebuild-image.sh` |
| План этажа «каша» на общем виде | Нормальный плотный DWG. Приблизить, слои, PDF. Не чинить деплой |

Не копировать приложение в `files/apps`. Не править `mimetypemapping.dist.json`.

После `occ upgrade` ядро затирает `files/core/img/filetypes` и `mimetypelist.js` — снова `./scripts/set-cad.sh` и Ctrl+F5.

## Контейнер убит по OOM

У Nextcloud лимит 1 GiB, у Collabora — 2 GiB. Смотрите `docker inspect` → `OOMKilled`. Не снимайте лимиты на хосте с 6 GiB RAM.

## База не подключается

Контейнер Postgres должен быть в сети `docker-lan`, имя хоста — как `POSTGRES_HOST`. Проверка из Nextcloud:

```bash
docker exec "$DOCKER_CONTAINER_NAME" php -r \
  'new PDO("pgsql:host=postgres;dbname=nextcloud","nextcloud","PASSWORD"); echo "ok\n";'
```

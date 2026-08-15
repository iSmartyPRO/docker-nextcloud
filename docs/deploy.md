# Деплой и обновление

Инструкция для исполнителя: человека или ИИ-агента. Выполнять **по шагам, без импровизации** в отмеченных местах. Если шаг не сходится с фактом на сервере — остановиться и спросить, не «чинить вокруг».

Связанные страницы: [install.md](install.md), [database.md](database.md), [collabora.md](collabora.md), [cad.md](cad.md), [smb.md](smb.md), [nginx.md](nginx.md), [troubleshooting.md](troubleshooting.md).

---

## 0. Роль исполнителя

1. Прочитать раздел **Инварианты** целиком.
2. Определить сценарий: **A** новый сервер с нуля, **B** обновление уже работающего стека, **C** перенос копии с другого хоста, **D** смена СУБД MariaDB → Postgres.
3. Сделать бэкап, если на диске уже есть `files/` или живая база.
4. Выполнить только выбранный сценарий, затем **матрицу проверки**.
5. Не коммитить `.env`, не печатать пароли в чат, логи, README.

Корень репозитория на сервере ниже называется `$ROOT` (каталог, где лежат `docker-compose.yml` и `.env`).

```bash
cd "$ROOT"
set -a && source .env && set +a
NC="$DOCKER_CONTAINER_NAME"          # например nextcloud
OCC="docker exec -u 33 $NC php occ"
```

Все `occ` — только так: пользователь UID 33 (`www-data`). Не root.

---

## 1. Инварианты (не нарушать)

| Запрет | Почему |
|---|---|
| Не ставить `image: nextcloud:latest` без `build` из `Dockerfile` | SMB и LibreDWG пропадут при первом recreate |
| Не лечить SMB/LibreDWG через `apt install` внутри уже запущенного контейнера | Следующий `compose up` снова сотрёт пакеты |
| Не делать `docker pull nextcloud` + `up` голого образа | Тот же эффект |
| Не сажать Nextcloud в чужую Postgres-базу | Отдельная роль и БД только для облака |
| Не поднимать OnlyOffice | Убран из стека; редактор — Collabora |
| Не снимать `mem_limit` / `memswap_limit` на хосте ≤6 GiB RAM | Collabora kit съест хост |
| Не выключать MariaDB, пока `occ config:system:get dbtype` не `pgsql` и проверки не зелёные | Откат |
| Не коммитить `.env`, `files/`, `backups/` | Секреты и данные |
| Не пропускать `collabora/apply-caps.sh` после смены образа CODE | Jail self-test снова упадёт |
| Не считать `occ files_external:verify` доказательством поломки SMB, если шара с логином пользователя | CLI без сессии всегда «No login credentials» |
| Не заканчивать деплой без `./scripts/set-cad.sh` | `.dwg` останется «неизвестным файлом»: серая иконка и «Сохранить» |
| Не править `files/resources/config/mimetypemapping.dist.json` | Затрёт обновление ядра; MIME только в `files/config/` |
| Не класть `files_cad` в `files/apps` | Затрёт `occ upgrade`; живёт в `custom_apps` через том `./apps/files_cad` |
| Не ставить `fileviewer` без `occ files_cad:configure-fileviewer` | docx/xlsx откроются не в Collabora |

Обязательные факты стека:

- Сеть Docker: внешняя `docker-lan` (compose **не** создаёт её сам).
- Nextcloud слушает `DOCKER_PORT` (обычно 8080), Collabora — `COLLABORA_PORT` (обычно 9980).
- Образ приложения: `cloud-nextcloud:local`, сборка из `Dockerfile` (вшиты `smbclient`, PHP `smbclient`, LibreDWG, `rsvg-convert`).
- Приложение чертежей: `./apps/files_cad` монтируется в `custom_apps/files_cad`. После смены compose — `docker compose up -d nextcloud`, иначе том не появится.
- Просмотр DWG: `./scripts/set-cad.sh` (MIME + иконки + `fileviewer` + `configure-fileviewer`). Без `occ maintenance:mimetype:update-db --repair-filecache` уже лежащие `.dwg` не откроются кликом.
- Тонкости CAD: [cad.md](cad.md).
- Лимиты: Nextcloud 1 GiB, Collabora 2 GiB, swap у них выключен (`memswap_limit` = `mem_limit`).
- `COLLABORA_WOPI_HOST` — hostname облака **без** `https://` (пример: `cloud.example.com`).
- Nginx / SSL обычно на другом контейнере или хосте. Этот репозиторий только отдаёт образцы в `nginx/`.

---

## 2. Ресурсы хоста

Минимум для Nextcloud + Redis + Collabora + отдельный Postgres:

- 4 vCPU
- 6 GiB RAM (лучше 8, если много одновременных документов)
- диск: `./files` растёт вместе с данными пользователей; система + образы ≈ 10–15 GiB

Перед работой:

```bash
nproc
free -h
df -h /
docker network inspect docker-lan >/dev/null
```

Если `docker-lan` нет: `docker network create docker-lan`.

---

## 3. Сценарий A — новый сервер, пустой инстанс

### A1. Код и `.env`

```bash
git clone <repo-url> "$ROOT"
cd "$ROOT"
cp .env.sample .env
```

Заполнить `.env` (не оставлять значения из sample):

- `DOCKER_CONTAINER_NAME`, `DOCKER_PORT`
- `NEXTCLOUD_ADMIN_*`
- `POSTGRES_HOST` — DNS-имя контейнера Postgres в `docker-lan`
- `POSTGRES_DB`, `POSTGRES_USER`, `POSTGRES_PASSWORD` — **новые**, только для облака
- `NEXTCLOUD_URL`, `THEMING_URL`, `COLLABORA_URL`, `COLLABORA_ALIASGROUP`, `COLLABORA_WOPI_HOST`
- `MAIL_*`, `LDAP_*`, `COLLABORA_ADMIN_*`

`COLLABORA_ALIASGROUP` обычно `https://<облако>:443`.

### A2. Postgres

На хосте с Postgres (тот же `docker-lan`):

```sql
CREATE ROLE nextcloud LOGIN PASSWORD '<POSTGRES_PASSWORD>';
CREATE DATABASE nextcloud OWNER nextcloud ENCODING 'UTF8' TEMPLATE template0;
```

Имена заменить на значения из `.env`. Не использовать существующую чужую БД.

Проверка с хоста облака:

```bash
docker run --rm --network docker-lan postgres:18-alpine \
  psql "postgresql://${POSTGRES_USER}:${POSTGRES_PASSWORD}@${POSTGRES_HOST}:5432/${POSTGRES_DB}" \
  -c 'SELECT current_user, current_database();'
```

### A3. Сборка и старт

```bash
cd "$ROOT"
mkdir -p files backups
docker compose build
docker compose up -d
docker compose ps
```

Ждать, пока Nextcloud станет `installed: true`:

```bash
$OCC status
```

Если контейнер только что создал `files/` — это нормально. Не копировать сюда чужой `files/` (это уже сценарий C).

### A4. Первичная настройка

По порядку:

```bash
./scripts/set-basics.sh
./scripts/set-theming.sh
./scripts/apps-enable.sh
./scripts/set-ldap.sh
./scripts/set-collabora.sh
./scripts/set-cad.sh
```

`set-basics.sh` выставляет `overwriteprotocol=https`, квоту, почту, индексы. Нужен для CSP/логина за HTTPS-прокси.

`set-cad.sh` обязателен: ядро Nextcloud не знает `.dwg`. Без него клик предлагает сохранить файл, иконка серая. После скрипта в браузере Ctrl+F5. Подробности и ловушки: [cad.md](cad.md).

### A5. Nginx (часто другой хост)

Скопировать и адаптировать:

- `nginx/cloud.conf.example` → `cloud.<domain>` на `:DOCKER_PORT`
- `nginx/collabora.conf.example` → `collabora.<domain>` на `:COLLABORA_PORT`

Обязательны `X-Forwarded-Proto`, WebSocket (`Upgrade` / `Connection`), большой `client_max_body_size` у облака.

Выпустить сертификаты. Прокси должен резолвить бэкенд (на том же хосте — `127.0.0.1`, в docker-сети — имя контейнера).

### A6. Jail Collabora

Если Collabora в `unhealthy` или в логах mount/self-test:

```bash
./collabora/apply-caps.sh
docker compose up -d collabora
```

Перейти к разделу 7 (проверка).

---

## 4. Сценарий B — обновление существующего сервера

Это путь «уже работает, нужно обновить код/образы/схему». Не создавать новую БД. Не запускать `set-ldap.sh` / `set-basics.sh` без нужды (они перезаписывают настройки).

### B1. Зафиксировать текущее состояние

```bash
cd "$ROOT"
$OCC status
$OCC config:system:get dbtype
$OCC config:system:get dbhost
$OCC user:report
docker compose ps
docker exec "$NC" php -m | grep -i smb
curl -sI -H "Host: $(echo "$NEXTCLOUD_URL" | sed 's#https://##')" http://127.0.0.1:${DOCKER_PORT}/status.php
```

Записать: версия Nextcloud, `dbtype`, число пользователей, SMB есть/нет.

### B2. Бэкап (обязательно)

```bash
mkdir -p backups
STAMP=$(date -u +%Y%m%dT%H%M%SZ)
cp -a files/config/config.php "backups/config.php.$STAMP"
docker exec "$POSTGRES_HOST" pg_dump -U "$POSTGRES_USER" "$POSTGRES_DB" \
  | gzip > "backups/${POSTGRES_DB}.$STAMP.sql.gz"
# при большом files/ — снимок каталога или тома, не только config
```

Проверить, что дамп не пустой (`gzip -t`, размер > 0).

### B3. Код

```bash
git status
git pull --ff-only
```

Если pull не fast-forward — остановиться. Не делать merge «на глаз» на проде.

Сверить, что в `docker-compose.yml` по-прежнему `build:` + `image: cloud-nextcloud:local`, тома Collabora из `./collabora/`, есть `COLLABORA_WOPI_HOST`. Если в `.env` нет `COLLABORA_WOPI_HOST` — добавить (hostname облака без схемы).

### B4. Образы

```bash
docker compose pull redis collabora
./scripts/rebuild-image.sh
```

`rebuild-image.sh` пересобирает Nextcloud **с SMB** и пересоздаёт контейнер. Каталог `./files` остаётся.

После смены Collabora:

```bash
./collabora/apply-caps.sh
docker compose up -d collabora
```

### B5. Миграции схемы Nextcloud

```bash
$OCC status
```

- `needsDbUpgrade: true` или сообщение про upgrade → идти дальше.
- `maintenance: true` без вашей команды — не снимать, пока не выполнен upgrade.

```bash
$OCC maintenance:mode --on
$OCC upgrade
$OCC db:add-missing-indices
$OCC db:add-missing-columns
$OCC db:add-missing-primary-keys
$OCC maintenance:repair
$OCC maintenance:mode --off
$OCC status
```

Если `upgrade` падает — **не** выключать maintenance, не откатывать файлы без дампа. Сохранить хвост лога, остановиться.

`db:convert-filecache-bigint` на уже мигрированном инстансе обычно no-op; повторный запуск безопасен, но не обязателен.

### B6. Приложения и редактор

```bash
$OCC app:update --all || true
$OCC richdocuments:activate-config
./scripts/set-cad.sh
```

`set-cad.sh` снова кладёт иконки DWG в `files/core/` (ядро их затирает при upgrade) и не даёт `fileviewer` забрать офисные форматы.

Не включать заново OnlyOffice. Не вызывать `apps-disable.sh` на проде без явной просьбы — он гасит много штатных приложений.

Перейти к разделу 7.

---

## 5. Сценарий C — перенос на новый сервер (копия живого инстанса)

1. На старом: бэкап как в B2 + архив `files/` (весь bind-mount) + копия `.env`.
2. На новом: клон репозитория, положить `.env`, распаковать `files/` в `$ROOT/files` (владельцы: как было, обычно `www-data` / UID 33).
3. Создать в Postgres **пустую** БД с теми же именем/ролью, что в `.env`, восстановить дамп.
4. `docker network create docker-lan` при необходимости.
5. `docker compose build && docker compose up -d` — **не** запускать мастер установки, `files/config/config.php` уже есть.
6. Проверить, что в `config.php` `dbhost` / `dbname` / пароль совпадают с новым Postgres (имя контейнера могло измениться).
7. `./collabora/apply-caps.sh` при необходимости.
8. `docker compose up -d nextcloud` — чтобы том `./apps/files_cad` точно сел; затем `./scripts/set-cad.sh` (идемпотентно: MIME, иконки, fileviewer).
9. Nginx и DNS на новый хост.
10. Раздел 7. Старый сервер не гасить, пока проверки не зелёные.

Не запускать `set-basics.sh` / `set-ldap.sh` сразу после переноса — они перепишут уже рабочие настройки. Только если что-то заведомо нужно обновить. `set-cad.sh` после переноса запускать можно.

---

## 6. Сценарий D — миграция MariaDB → PostgreSQL

Делать только если `occ config:system:get dbtype` = `mysql` и есть задача сменить СУБД. На чистом Postgres этот раздел пропустить.

### D1. Подготовка

- Дамп MariaDB + копия `config.php` (B2).
- Пустая Postgres-БД и роль **только** для облака. Права: владелец БД и схемы `public`.
- Проверка `pdo_pgsql` в контейнере: `docker exec "$NC" php -m | grep pdo_pgsql`.
- Связность: из контейнера Nextcloud PDO к `POSTGRES_HOST`.

### D2. Конвертация

```bash
$OCC maintenance:mode --on
# пароль лучше через stdin / --password, не светить в history
$OCC db:convert-type -n --all-apps pgsql "$POSTGRES_USER" "$POSTGRES_HOST" "$POSTGRES_DB"
```

Ожидаемый сбой Nextcloud 34: в конце

```
SELECT setval('oc_jobs_id_seq', (SELECT MAX() FROM ))
```

или `setval ... out of bounds` (id в `oc_jobs` — snowflake > integer).

`config.php` при падении часто **ещё mysql** — это хорошо.

Тогда:

1. Сверить число таблиц и ключевых строк (`oc_users`, `oc_filecache`, `oc_ldap_user_mapping`, `oc_jobs`, `oc_appconfig`). Таблицы удалённого OnlyOffice можно не переносить.
2. В Postgres выполнить:

```sql
DO $$
DECLARE r record;
BEGIN
  FOR r IN
    SELECT n.nspname AS nsp, c.relname AS seq
    FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE c.relkind = 'S' AND n.nspname = 'public'
  LOOP
    EXECUTE format('ALTER SEQUENCE %I.%I AS bigint', r.nsp, r.seq);
  END LOOP;
END $$;

DO $$
DECLARE r record; max_id bigint;
BEGIN
  FOR r IN
    SELECT n.nspname AS nsp, c.relname AS seq, t.relname AS tbl, a.attname AS col
    FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    JOIN pg_depend d ON d.objid = c.oid AND d.deptype = 'a'
    JOIN pg_class t ON t.oid = d.refobjid
    JOIN pg_attribute a ON a.attrelid = t.oid AND a.attnum = d.refobjsubid
    WHERE c.relkind = 'S' AND n.nspname = 'public'
  LOOP
    EXECUTE format('SELECT COALESCE(MAX(%I), 0) FROM %I.%I', r.col, r.nsp, r.tbl) INTO max_id;
    IF max_id > 0 THEN
      EXECUTE format('SELECT setval(%L, %s)', r.nsp || '.' || r.seq, max_id);
    ELSE
      EXECUTE format('SELECT setval(%L, 1, false)', r.nsp || '.' || r.seq);
    END IF;
  END LOOP;
END $$;
```

3. Переключить `config.php`: `dbtype=pgsql`, `dbhost=$POSTGRES_HOST`, `dbname`, `dbuser`, `dbpassword`, при необходимости `dbport=5432`.
4. В compose / `.env` заменить `MYSQL_*` на `POSTGRES_*` (как в текущем репозитории).
5. `$OCC status` — `needsDbUpgrade: false`.
6. `$OCC user:report` — те же цифры, что до миграции (LDAP виден **после** `maintenance:mode --off`).
7. `$OCC richdocuments:activate-config`.
8. Матрица проверки. Только потом `docker stop` MariaDB и `docker update --restart=no`. Данные MariaDB не удалять несколько дней.

---

## 7. Матрица проверки (все сценарии)

Не объявлять успех, пока не пройдено.

| # | Проверка | Ожидание |
|---|---|---|
| 1 | `docker compose ps` | `nextcloud`, `redis`, `collabora` Up; Collabora `healthy` |
| 2 | `$OCC status` | `installed: true`, `maintenance: false`, `needsDbUpgrade: false` |
| 3 | `$OCC config:system:get dbtype` | `pgsql` |
| 4 | `$OCC user:report` | Пользователи на месте (LDAP не ноль, если AD включён) |
| 5 | `docker exec $NC php -m \| grep smb` | Есть `smbclient` и/или `libsmbclient` |
| 6 | `docker exec $NC smbclient -V` | Версия Samba |
| 7 | `curl -s http://127.0.0.1:$DOCKER_PORT/status.php` | JSON, `installed: true` |
| 8 | HTTPS логин (локальный админ и LDAP) | Вход без «обновите страницу» |
| 9 | Файлы и шара SMB в веб-UI | Каталог открывается под пользователем AD |
| 10 | `curl -sk $COLLABORA_URL/hosting/capabilities` | JSON/XML, не 502 |
| 11 | `$OCC richdocuments:activate-config` | discovery + capabilities OK |
| 12 | Открыть docx/xlsx в браузере | Редактор Collabora, не File Viewer и не OnlyOffice |
| 13 | `$OCC app:list \| grep -E 'files_cad\|fileviewer'` | Оба enabled |
| 14 | Открыть `.dwg` в веб-UI (Ctrl+F5) | Красная иконка AutoCAD; клик открывает чертёж, не «Сохранить» |
| 15 | `docker inspect $NC --format '{{.HostConfig.Memory}}'` | 1073741824 (1 GiB) |
| 16 | `docker inspect ${NC}_collabora --format '{{.HostConfig.Memory}}'` | 2147483648 (2 GiB) |

Пункт 14 важнее наличия `dwg2SVG`. Конвертер нужен только для миниатюр в списке; его нет — не откатывать деплой, если клик по DWG уже открывает чертёж. После смены MIME в браузере обязателен Ctrl+F5.

Пункт 9 из CLI не подменять `files_external:verify`, если authentication = login credentials.

---

## 8. Откат

### После неудачного `occ upgrade` (сценарий B)

1. Оставить maintenance **вкл**.
2. Восстановить `files/config/config.php` из `backups/`.
3. Восстановить Postgres из `backups/*.sql.gz` в ту же БД (или во временную и переключить `dbname`).
4. Вернуть предыдущий git-тег/коммит, `./scripts/rebuild-image.sh`.
5. `$OCC maintenance:mode --off` только когда `status` зелёный.

### После неудачной смены СУБД (сценарий D)

1. Вернуть `config.php` с `dbtype=mysql`.
2. Запустить MariaDB, если останавливали.
3. Не дропать новую Postgres-базу — она может пригодиться для повторной попытки (`--clear-schema`).

### После переноса (сценарий C)

Держать старый сервер доступным, пока новый не прошёл матрицу. DNS переключать последним.

---

## 9. Когда остановиться и спросить

- `git pull` не fast-forward, конфликт.
- `occ upgrade` падает.
- Число пользователей после работ меньше, чем в B1.
- SMB-модулей нет после `rebuild-image.sh`.
- Collabora unhealthy после `apply-caps.sh`.
- На хосте нет `docker-lan`, но есть другая сеть с живыми БД — не создавать вторую «наугад».
- В `.env` и `config.php` разные пароли/хосты БД.
- Свободно < 5 GiB на диске или RAM available < 1 GiB перед обновлением.
- Просят «просто поднять OnlyOffice обратно» — это смена архитектуры, не часть этого runbook.
- После `set-cad.sh` клик по `.dwg` всё ещё «Сохранить» — не ставить другой CAD с водяным знаком. Идти в [cad.md](cad.md) (MIME / filecache / том / Ctrl+F5).
- `docker exec $NC test -f /var/www/html/custom_apps/files_cad/appinfo/info.xml` падает после правки compose — не копировать в `files/apps`, а `docker compose up -d nextcloud`.

---

## 10. Краткая шпаргалка команд

```bash
# сборка Nextcloud со SMB и LibreDWG (миниатюры DWG)
./scripts/rebuild-image.sh

# DWG: MIME, иконки, fileviewer, не отдать офис File Viewer
./scripts/set-cad.sh

# Collabora после pull образа
./collabora/apply-caps.sh
docker compose up -d collabora

# схема
docker exec -u 33 "$DOCKER_CONTAINER_NAME" php occ upgrade
docker exec -u 33 "$DOCKER_CONTAINER_NAME" php occ db:add-missing-indices
docker exec -u 33 "$DOCKER_CONTAINER_NAME" php occ db:add-missing-columns
docker exec -u 33 "$DOCKER_CONTAINER_NAME" php occ db:add-missing-primary-keys
./scripts/set-cad.sh   # ядро затёрло иконки DWG в files/core/

# здоровье
docker exec -u 33 "$DOCKER_CONTAINER_NAME" php occ status
docker exec -u 33 "$DOCKER_CONTAINER_NAME" php occ user:report
docker exec -u 33 "$DOCKER_CONTAINER_NAME" php occ richdocuments:activate-config
```

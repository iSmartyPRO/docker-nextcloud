# Установка

Короткий путь до первого входа. Полный runbook (новый сервер, обновление, перенос, смена СУБД): [deploy.md](deploy.md).

## Требования

- Docker 24+ и Docker Compose v2
- Внешняя сеть `docker-lan`
- PostgreSQL (отдельный контейнер в той же сети)
- 4 vCPU и от 6 GiB RAM, если вместе крутятся Nextcloud и Collabora. Для просмотра DWG в браузере отдельная RAM на сервере не нужна.
- Свободный диск: данные живут в `./files`

## Сеть

```bash
docker network create docker-lan
```

Compose подключает сервисы к уже существующей сети `docker-lan`.

## Первый запуск

```bash
cp .env.sample .env
# заполните пароли, домены, LDAP, Postgres

docker compose build
docker compose up -d
```

Образ Nextcloud собирается локально (`cloud-nextcloud:local`): в него вшиты SMB и LibreDWG (миниатюры DWG). Просмотр чертежей кликом включает `./scripts/set-cad.sh` — без него `.dwg` скачивается как неизвестный файл. Тонкости: [cad.md](cad.md).

Создайте в PostgreSQL отдельную базу и роль (не используйте чужую БД):

```sql
CREATE ROLE nextcloud LOGIN PASSWORD 'strong-password';
CREATE DATABASE nextcloud OWNER nextcloud ENCODING 'UTF8' TEMPLATE template0;
```

Имена и пароль должны совпадать с `POSTGRES_*` в `.env`.

После первого старта:

```bash
./scripts/set-basics.sh
./scripts/set-theming.sh
./scripts/apps-enable.sh
./scripts/set-ldap.sh
./scripts/set-collabora.sh
./scripts/set-cad.sh
```

После `set-cad.sh` в браузере **Ctrl+F5**, затем открыть пробный `.dwg`: красная иконка AutoCAD, клик не предлагает «Сохранить». docx должен остаться в Collabora.

## Остановка

```bash
docker compose down
```

Том `./files` и база PostgreSQL не удаляются.

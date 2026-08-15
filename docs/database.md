# База данных

Nextcloud 34 поддерживает PostgreSQL 14–18. Этот стек рассчитан на внешний Postgres в сети `docker-lan`.

## Рекомендуемая схема

Отдельная роль и база только для Nextcloud. Не сажайте облако в чужую уже занятую БД.

```sql
CREATE ROLE nextcloud LOGIN PASSWORD 'strong-password';
CREATE DATABASE nextcloud OWNER nextcloud ENCODING 'UTF8' TEMPLATE template0;
```

В `.env`:

```
POSTGRES_HOST=postgres
POSTGRES_DB=nextcloud
POSTGRES_USER=nextcloud
POSTGRES_PASSWORD=strong-password
```

## Миграция с MariaDB

Если инстанс уже жил на MySQL/MariaDB:

1. Снимите дамп MariaDB и копию `files/config/config.php`.
2. Создайте пустую базу в Postgres.
3. Включите maintenance: `occ maintenance:mode --on`.
4. Выполните `occ db:convert-type pgsql <user> <host> <database>`.
5. Если конвертер упадёт на `setval` для `oc_jobs` (snowflake id больше integer) — переведите sequences на `bigint` и выставьте `setval` по `MAX(id)`.
6. Переключите `config.php` на `dbtype=pgsql` и `dbhost` Postgres.
7. Проверьте `occ status`, `occ user:report`, вход и Collabora.
8. Только после этого останавливайте MariaDB.

Таблицы удалённых приложений (например OnlyOffice) можно не переносить.

## Лимиты

У контейнера Nextcloud лимит 1 GiB RAM, у Collabora — 2 GiB. Postgres обычно ограничен отдельно (в своём compose).

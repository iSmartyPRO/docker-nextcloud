# Database

Nextcloud 34 supports PostgreSQL 14–18. This stack expects an external Postgres on `docker-lan`.

## Recommended layout

A dedicated role and database for Nextcloud only. Do not put the cloud into someone else’s already used database.

```sql
CREATE ROLE nextcloud LOGIN PASSWORD 'strong-password';
CREATE DATABASE nextcloud OWNER nextcloud ENCODING 'UTF8' TEMPLATE template0;
```

In `.env`:

```
POSTGRES_HOST=postgres
POSTGRES_DB=nextcloud
POSTGRES_USER=nextcloud
POSTGRES_PASSWORD=strong-password
```

## Migrate from MariaDB

If the instance already ran on MySQL/MariaDB:

1. Take a MariaDB dump and a copy of `files/config/config.php`.
2. Create an empty database in Postgres.
3. Turn maintenance on: `occ maintenance:mode --on`.
4. Run `occ db:convert-type pgsql <user> <host> <database>`.
5. If the converter fails on `setval` for `oc_jobs` (snowflake id larger than integer) — alter sequences to `bigint` and set `setval` from `MAX(id)`.
6. Switch `config.php` to `dbtype=pgsql` and the Postgres `dbhost`.
7. Check `occ status`, `occ user:report`, login, and Collabora.
8. Only then stop MariaDB.

Tables from removed apps (for example OnlyOffice) can be skipped.

## Limits

The Nextcloud container is limited to 1 GiB RAM, Collabora to 2 GiB. Postgres is usually limited in its own compose file.

# Deploy and upgrade

Runbook for an operator: a person or an AI agent. Follow the marked steps **in order, without improvising**. If a step does not match the fact on the server — stop and ask. Do not “fix around it”.

Related pages: [install.md](install.md), [database.md](database.md), [collabora.md](collabora.md), [cad.md](cad.md), [smb.md](smb.md), [nginx.md](nginx.md), [troubleshooting.md](troubleshooting.md).

---

## 0. Operator role

1. Read the **Invariants** section in full.
2. Pick a scenario: **A** new empty host, **B** upgrade of a running stack, **C** move a copy from another host, **D** MariaDB → Postgres.
3. Take a backup if `files/` or a live database already exists on disk.
4. Run only the chosen scenario, then the **verification matrix**.
5. Do not commit `.env`. Do not print passwords in chat, logs, or the README.

The repository root on the server is `$ROOT` (the directory that holds `docker-compose.yml` and `.env`).

```bash
cd "$ROOT"
set -a && source .env && set +a
NC="$DOCKER_CONTAINER_NAME"          # e.g. nextcloud
OCC="docker exec -u 33 $NC php occ"
```

All `occ` commands run this way: UID 33 (`www-data`). Not root.

---

## 1. Invariants (do not break)

| Do not | Why |
|---|---|
| Do not set `image: nextcloud:latest` without a `build` from the `Dockerfile` | SMB and LibreDWG disappear on the first recreate |
| Do not “fix” SMB/LibreDWG with `apt install` inside a running container | The next `compose up` wipes the packages again |
| Do not `docker pull nextcloud` and `up` a stock image | Same effect |
| Do not put Nextcloud into someone else’s Postgres database | Dedicated role and database for the cloud only |
| Do not start OnlyOffice | Removed from the stack; the editor is Collabora |
| Do not lift `mem_limit` / `memswap_limit` on a host with ≤6 GiB RAM | The Collabora kit will eat the host |
| Do not stop MariaDB until `occ config:system:get dbtype` is `pgsql` and checks are green | Rollback |
| Do not commit `.env`, `files/`, `backups/` | Secrets and data |
| Do not skip `collabora/apply-caps.sh` after a CODE image change | Jail self-test fails again |
| Do not treat `occ files_external:verify` as proof that SMB is broken when the share uses user login | CLI without a session always says “No login credentials” |
| Do not finish a deploy without `./scripts/set-cad.sh` | `.dwg` stays an “unknown file”: grey icon and “Save” |
| Do not edit `files/resources/config/mimetypemapping.dist.json` | A core upgrade overwrites it; MIME lives in `files/config/` |
| Do not put `files_cad` in `files/apps` | `occ upgrade` overwrites it; it lives in `custom_apps` via `./apps/files_cad` |
| Do not install `fileviewer` without `occ files_cad:configure-fileviewer` | docx/xlsx open outside Collabora |

Hard facts about the stack:

- Docker network: external `docker-lan` (compose does **not** create it).
- Nextcloud listens on `DOCKER_PORT` (usually 8080), Collabora on `COLLABORA_PORT` (usually 9980).
- Application image: `cloud-nextcloud:local`, built from the `Dockerfile` (`smbclient`, PHP `smbclient`, LibreDWG, `rsvg-convert`).
- Drawing app: `./apps/files_cad` mounts into `custom_apps/files_cad`. After a compose change, run `docker compose up -d nextcloud` or the volume will not appear.
- DWG viewing: `./scripts/set-cad.sh` (MIME + icons + `fileviewer` + `configure-fileviewer`). Without `occ maintenance:mimetype:update-db --repair-filecache`, existing `.dwg` files will not open on click.
- CAD details: [cad.md](cad.md).
- Limits: Nextcloud 1 GiB, Collabora 2 GiB, swap off (`memswap_limit` = `mem_limit`).
- `COLLABORA_WOPI_HOST` is the cloud hostname **without** `https://` (example: `cloud.example.com`).
- Nginx / TLS usually live on another container or host. This repository only ships samples in `nginx/`.

---

## 2. Host resources

Minimum for Nextcloud + Redis + Collabora + a separate Postgres:

- 4 vCPU
- 6 GiB RAM (8 is better if many documents are open at once)
- disk: `./files` grows with user data; system + images ≈ 10–15 GiB

Before you start:

```bash
nproc
free -h
df -h /
docker network inspect docker-lan >/dev/null
```

If `docker-lan` is missing: `docker network create docker-lan`.

---

## 3. Scenario A — new host, empty instance

### A1. Code and `.env`

```bash
git clone <repo-url> "$ROOT"
cd "$ROOT"
cp .env.sample .env
```

Fill `.env` (do not leave sample values):

- `DOCKER_CONTAINER_NAME`, `DOCKER_PORT`
- `NEXTCLOUD_ADMIN_*`
- `POSTGRES_HOST` — DNS name of the Postgres container on `docker-lan`
- `POSTGRES_DB`, `POSTGRES_USER`, `POSTGRES_PASSWORD` — **new**, for the cloud only
- `NEXTCLOUD_URL`, `THEMING_URL`, `COLLABORA_URL`, `COLLABORA_ALIASGROUP`, `COLLABORA_WOPI_HOST`
- `MAIL_*`, `LDAP_*`, `COLLABORA_ADMIN_*`

`COLLABORA_ALIASGROUP` is usually `https://<cloud-host>:443`.

### A2. Postgres

On the Postgres host (same `docker-lan`):

```sql
CREATE ROLE nextcloud LOGIN PASSWORD '<POSTGRES_PASSWORD>';
CREATE DATABASE nextcloud OWNER nextcloud ENCODING 'UTF8' TEMPLATE template0;
```

Replace names with the values from `.env`. Do not reuse someone else’s database.

Check from the cloud host:

```bash
docker run --rm --network docker-lan postgres:18-alpine \
  psql "postgresql://${POSTGRES_USER}:${POSTGRES_PASSWORD}@${POSTGRES_HOST}:5432/${POSTGRES_DB}" \
  -c 'SELECT current_user, current_database();'
```

### A3. Build and start

```bash
cd "$ROOT"
mkdir -p files backups
docker compose build
docker compose up -d
docker compose ps
```

Wait until Nextcloud reports `installed: true`:

```bash
$OCC status
```

If the container just created `files/`, that is expected. Do not copy another host’s `files/` here (that is scenario C).

### A4. First-time setup

In this order:

```bash
./scripts/set-basics.sh
./scripts/set-theming.sh
./scripts/apps-enable.sh
./scripts/set-ldap.sh
./scripts/set-collabora.sh
./scripts/set-cad.sh
```

`set-basics.sh` sets `overwriteprotocol=https`, quota, mail, and indexes. Required for CSP / login behind an HTTPS proxy.

`set-cad.sh` is mandatory: Nextcloud core does not know `.dwg`. Without it, a click offers to save the file and the icon stays grey. After the script, hard-refresh the browser (Ctrl+F5). Details and pitfalls: [cad.md](cad.md).

### A5. Nginx (often another host)

Copy and adapt:

- `nginx/cloud.conf.example` → `cloud.<domain>` on `:DOCKER_PORT`
- `nginx/collabora.conf.example` → `collabora.<domain>` on `:COLLABORA_PORT`

Required: `X-Forwarded-Proto`, WebSocket (`Upgrade` / `Connection`), a large `client_max_body_size` on the cloud vhost.

Issue certificates. The proxy must resolve the backend (same host: `127.0.0.1`; docker network: container name).

### A6. Collabora jail

If Collabora is `unhealthy` or logs show a mount/self-test failure:

```bash
./collabora/apply-caps.sh
docker compose up -d collabora
```

Go to section 7 (verification).

---

## 4. Scenario B — upgrade an existing server

This is “it already works; update code / images / schema”. Do not create a new database. Do not run `set-ldap.sh` / `set-basics.sh` unless you mean to overwrite settings.

### B1. Record the current state

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

Write down: Nextcloud version, `dbtype`, user count, SMB present or not.

### B2. Backup (mandatory)

```bash
mkdir -p backups
STAMP=$(date -u +%Y%m%dT%H%M%SZ)
cp -a files/config/config.php "backups/config.php.$STAMP"
docker exec "$POSTGRES_HOST" pg_dump -U "$POSTGRES_USER" "$POSTGRES_DB" \
  | gzip > "backups/${POSTGRES_DB}.$STAMP.sql.gz"
# if files/ is large — snapshot the directory or volume, not only config
```

Confirm the dump is not empty (`gzip -t`, size > 0).

### B3. Code

```bash
git status
git pull --ff-only
```

If the pull is not fast-forward — stop. Do not merge “by eye” on production.

Confirm `docker-compose.yml` still has `build:` + `image: cloud-nextcloud:local`, Collabora volumes from `./collabora/`, and `COLLABORA_WOPI_HOST`. If `.env` has no `COLLABORA_WOPI_HOST`, add it (cloud hostname, no scheme).

### B4. Images

```bash
docker compose pull redis collabora
./scripts/rebuild-image.sh
```

`rebuild-image.sh` rebuilds Nextcloud **with SMB** and recreates the container. `./files` stays.

After a Collabora image change:

```bash
./collabora/apply-caps.sh
docker compose up -d collabora
```

### B5. Nextcloud schema migrations

```bash
$OCC status
```

- `needsDbUpgrade: true` or an upgrade message → continue.
- `maintenance: true` that you did not set — do not turn it off until upgrade finishes.

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

If `upgrade` fails — **do not** turn maintenance off, do not roll files back without a dump. Keep the tail of the log and stop.

`db:convert-filecache-bigint` is usually a no-op on an already migrated instance. A second run is safe but not required.

### B6. Apps and editor

```bash
$OCC app:update --all || true
$OCC richdocuments:activate-config
./scripts/set-cad.sh
```

`set-cad.sh` puts DWG icons back into `files/core/` (core wipes them on upgrade) and keeps `fileviewer` off office formats.

Do not enable OnlyOffice again. Do not run `apps-disable.sh` on production unless someone explicitly asked — it turns off many stock apps.

Go to section 7.

---

## 5. Scenario C — move to a new host (copy of a live instance)

1. On the old host: backup as in B2 + archive of `files/` (the whole bind-mount) + a copy of `.env`.
2. On the new host: clone the repo, place `.env`, unpack `files/` into `$ROOT/files` (owners as before, usually `www-data` / UID 33).
3. Create an **empty** Postgres database with the same name/role as in `.env`, restore the dump.
4. `docker network create docker-lan` if needed.
5. `docker compose build && docker compose up -d` — **do not** run the install wizard; `files/config/config.php` already exists.
6. Confirm `config.php` `dbhost` / `dbname` / password match the new Postgres (the container name may have changed).
7. `./collabora/apply-caps.sh` if needed.
8. `docker compose up -d nextcloud` so the `./apps/files_cad` volume is attached; then `./scripts/set-cad.sh` (idempotent: MIME, icons, fileviewer).
9. Point nginx and DNS at the new host.
10. Section 7. Do not shut down the old server until checks are green.

Do not run `set-basics.sh` / `set-ldap.sh` right after a move — they overwrite working settings. Only if something must be updated on purpose. `set-cad.sh` after a move is fine.

---

## 6. Scenario D — MariaDB → PostgreSQL

Do this only if `occ config:system:get dbtype` is `mysql` and the task is to change the engine. Skip this section on a clean Postgres install.

### D1. Prepare

- MariaDB dump + a copy of `config.php` (B2).
- Empty Postgres database and role **for the cloud only**. Rights: owner of the database and the `public` schema.
- Confirm `pdo_pgsql` in the container: `docker exec "$NC" php -m | grep pdo_pgsql`.
- Connectivity: PDO from the Nextcloud container to `POSTGRES_HOST`.

### D2. Convert

```bash
$OCC maintenance:mode --on
# pass the password via stdin / --password, do not leave it in history
$OCC db:convert-type -n --all-apps pgsql "$POSTGRES_USER" "$POSTGRES_HOST" "$POSTGRES_DB"
```

Expected Nextcloud 34 failure at the end:

```
SELECT setval('oc_jobs_id_seq', (SELECT MAX() FROM ))
```

or `setval ... out of bounds` (`oc_jobs` ids are snowflakes larger than integer).

On failure, `config.php` is often **still mysql** — that is good.

Then:

1. Compare table counts and key row counts (`oc_users`, `oc_filecache`, `oc_ldap_user_mapping`, `oc_jobs`, `oc_appconfig`). Tables from a removed OnlyOffice can be skipped.
2. In Postgres run:

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

3. Switch `config.php`: `dbtype=pgsql`, `dbhost=$POSTGRES_HOST`, `dbname`, `dbuser`, `dbpassword`, and `dbport=5432` if needed.
4. In compose / `.env` replace `MYSQL_*` with `POSTGRES_*` (as in this repository).
5. `$OCC status` — `needsDbUpgrade: false`.
6. `$OCC user:report` — same numbers as before the migration (LDAP is visible **after** `maintenance:mode --off`).
7. `$OCC richdocuments:activate-config`.
8. Verification matrix. Only then `docker stop` MariaDB and `docker update --restart=no`. Keep MariaDB data for a few days.

---

## 7. Verification matrix (every scenario)

Do not call it done until this passes.

| # | Check | Expected |
|---|---|---|
| 1 | `docker compose ps` | `nextcloud`, `redis`, `collabora` Up; Collabora `healthy` |
| 2 | `$OCC status` | `installed: true`, `maintenance: false`, `needsDbUpgrade: false` |
| 3 | `$OCC config:system:get dbtype` | `pgsql` |
| 4 | `$OCC user:report` | Users still there (LDAP is not zero if AD is on) |
| 5 | `docker exec $NC php -m \| grep smb` | `smbclient` and/or `libsmbclient` |
| 6 | `docker exec $NC smbclient -V` | Samba version |
| 7 | `curl -s http://127.0.0.1:$DOCKER_PORT/status.php` | JSON, `installed: true` |
| 8 | HTTPS login (local admin and LDAP) | Sign-in without “reload the page” |
| 9 | Files and an SMB share in the web UI | Folder opens as the AD user |
| 10 | `curl -sk $COLLABORA_URL/hosting/capabilities` | JSON/XML, not 502 |
| 11 | `$OCC richdocuments:activate-config` | discovery + capabilities OK |
| 12 | Open docx/xlsx in the browser | Collabora editor, not File Viewer or OnlyOffice |
| 13 | `$OCC app:list \| grep -E 'files_cad\|fileviewer'` | Both enabled |
| 14 | Open a `.dwg` in the web UI (Ctrl+F5) | Red AutoCAD icon; click opens the drawing, not “Save” |
| 15 | `docker inspect $NC --format '{{.HostConfig.Memory}}'` | 1073741824 (1 GiB) |
| 16 | `docker inspect ${NC}_collabora --format '{{.HostConfig.Memory}}'` | 2147483648 (2 GiB) |

Item 14 matters more than `dwg2SVG`. The converter is only for list thumbnails. If it is missing, do not roll back the deploy when a DWG click already opens the drawing. After a MIME change, Ctrl+F5 in the browser is mandatory.

Do not replace item 9 with `files_external:verify` from the CLI when authentication is login credentials.

---

## 8. Rollback

### After a failed `occ upgrade` (scenario B)

1. Leave maintenance **on**.
2. Restore `files/config/config.php` from `backups/`.
3. Restore Postgres from `backups/*.sql.gz` into the same database (or a temporary one and switch `dbname`).
4. Return to the previous git tag/commit, `./scripts/rebuild-image.sh`.
5. `$OCC maintenance:mode --off` only when `status` is green.

### After a failed engine change (scenario D)

1. Restore `config.php` with `dbtype=mysql`.
2. Start MariaDB if you stopped it.
3. Do not drop the new Postgres database — you may need it for a retry (`--clear-schema`).

### After a move (scenario C)

Keep the old server reachable until the new one passes the matrix. Switch DNS last.

---

## 9. When to stop and ask

- `git pull` is not fast-forward, conflict.
- `occ upgrade` fails.
- User count after the work is lower than in B1.
- SMB modules are missing after `rebuild-image.sh`.
- Collabora is unhealthy after `apply-caps.sh`.
- The host has no `docker-lan`, but another network already holds live databases — do not create a second one “at random”.
- `.env` and `config.php` have different database passwords/hosts.
- Free disk < 5 GiB or available RAM < 1 GiB before an upgrade.
- Someone asks to “just bring OnlyOffice back” — that is an architecture change, not part of this runbook.
- After `set-cad.sh` a `.dwg` click still says “Save” — do not install another CAD viewer with a watermark. Go to [cad.md](cad.md) (MIME / filecache / volume / Ctrl+F5).
- `docker exec $NC test -f /var/www/html/custom_apps/files_cad/appinfo/info.xml` fails after a compose edit — do not copy into `files/apps`; run `docker compose up -d nextcloud`.

---

## 10. Command cheat sheet

```bash
# rebuild Nextcloud with SMB and LibreDWG (DWG thumbnails)
./scripts/rebuild-image.sh

# DWG: MIME, icons, fileviewer, keep office files off File Viewer
./scripts/set-cad.sh

# Collabora after an image pull
./collabora/apply-caps.sh
docker compose up -d collabora

# schema
docker exec -u 33 "$DOCKER_CONTAINER_NAME" php occ upgrade
docker exec -u 33 "$DOCKER_CONTAINER_NAME" php occ db:add-missing-indices
docker exec -u 33 "$DOCKER_CONTAINER_NAME" php occ db:add-missing-columns
docker exec -u 33 "$DOCKER_CONTAINER_NAME" php occ db:add-missing-primary-keys
./scripts/set-cad.sh   # core overwrote DWG icons in files/core/

# health
docker exec -u 33 "$DOCKER_CONTAINER_NAME" php occ status
docker exec -u 33 "$DOCKER_CONTAINER_NAME" php occ user:report
docker exec -u 33 "$DOCKER_CONTAINER_NAME" php occ richdocuments:activate-config
```

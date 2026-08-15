# Operations

Every script reads `.env` from the repository root. Run them from any directory:

```bash
./scripts/apps-list.sh
```

## occ

```bash
docker exec -u 33 "$DOCKER_CONTAINER_NAME" php occ list
docker exec -u 33 "$DOCKER_CONTAINER_NAME" php occ status
docker exec -u 33 "$DOCKER_CONTAINER_NAME" php occ user:report
```

`www-data` in the container is UID 33.

## Apps

```bash
./scripts/apps-list.sh
./scripts/apps-enable.sh    # LDAP + files_external
./scripts/set-cad.sh        # DWG/DXF viewing and thumbnails
./scripts/apps-disable.sh   # disable extra stock apps
./scripts/background-job.sh # background-job window
```

Step-by-step upgrade with backup and schema migrations: [deploy.md](deploy.md) (scenario B).

## Upgrade Nextcloud

```bash
docker compose pull redis collabora
./scripts/rebuild-image.sh
docker exec -u 33 "$DOCKER_CONTAINER_NAME" php occ upgrade
docker exec -u 33 "$DOCKER_CONTAINER_NAME" php occ db:add-missing-indices
```

`rebuild-image.sh` rebuilds `cloud-nextcloud:local` from the current `nextcloud:latest` and keeps SMB and LibreDWG.

After `occ upgrade`, core overwrites `files/core/` (DWG icons and `mimetypelist.js`). Immediately:

```bash
./scripts/set-cad.sh
```

Otherwise `.dwg` becomes a grey file with a save dialog again. Details: [cad.md](cad.md).

## Upgrade Collabora

```bash
docker compose pull collabora
./collabora/apply-caps.sh
docker compose up -d collabora
./scripts/set-collabora.sh
```

## Backup

You need three things:

1. The `./files` directory (code, `config.php`, `data/`)
2. A PostgreSQL dump of `POSTGRES_DB`
3. `.env` (store separately, not in git)

```bash
set -a && source .env && set +a
mkdir -p backups
docker exec "$POSTGRES_HOST" pg_dump -U "$POSTGRES_USER" "$POSTGRES_DB" \
  | gzip > "backups/${POSTGRES_DB}-$(date +%F).sql.gz"
```

`backups/` is not in git.

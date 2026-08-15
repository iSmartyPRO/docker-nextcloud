# Install

Short path to the first login. Full runbook (new host, upgrade, move, database change): [deploy.md](deploy.md).

## Requirements

- Docker 24+ and Docker Compose v2
- External network `docker-lan`
- PostgreSQL (a separate container on the same network)
- 4 vCPU and at least 6 GiB RAM if Nextcloud and Collabora run together. In-browser DWG viewing does not need extra server RAM.
- Free disk: data lives in `./files`

## Network

```bash
docker network create docker-lan
```

Compose attaches services to the existing `docker-lan` network.

## First start

```bash
cp .env.sample .env
# fill in passwords, domains, LDAP, Postgres

docker compose build
docker compose up -d
```

The Nextcloud image is built locally (`cloud-nextcloud:local`) with SMB and LibreDWG (DWG thumbnails). Click-to-view is enabled by `./scripts/set-cad.sh` — without it, `.dwg` downloads as an unknown file. Details: [cad.md](cad.md).

Create a dedicated PostgreSQL role and database (do not reuse someone else’s database):

```sql
CREATE ROLE nextcloud LOGIN PASSWORD 'strong-password';
CREATE DATABASE nextcloud OWNER nextcloud ENCODING 'UTF8' TEMPLATE template0;
```

Names and password must match `POSTGRES_*` in `.env`.

After the first start:

```bash
./scripts/set-basics.sh
./scripts/set-theming.sh
./scripts/apps-enable.sh
./scripts/set-ldap.sh
./scripts/set-collabora.sh
./scripts/set-cad.sh
```

After `set-cad.sh`, hard-refresh the browser (**Ctrl+F5**), then open a sample `.dwg`: red AutoCAD icon, click does not offer “Save”. A docx must stay in Collabora.

## Stop

```bash
docker compose down
```

The `./files` volume and the PostgreSQL database are not removed.

# Configuration

All secrets live in `.env` only (the file is not in git). Sample: `.env.sample`.

## Main variables

| Variable | Purpose |
|---|---|
| `DOCKER_CONTAINER_NAME` | Nextcloud container name |
| `DOCKER_PORT` | Host port (default 8080) |
| `NEXTCLOUD_ADMIN_USER` / `NEXTCLOUD_ADMIN_PASSWORD` | Local administrator |
| `POSTGRES_HOST` / `POSTGRES_DB` / `POSTGRES_USER` / `POSTGRES_PASSWORD` | Database |
| `NEXTCLOUD_URL` | Public HTTPS URL of the cloud |
| `MAIL_*` | Outbound mail |
| `LDAP_*` | Active Directory |
| `THEMING_NAME` / `THEMING_SLOGAN` / `THEMING_URL` / `THEMING_PRIMARYCOLOR` | Name, slogan, color, URL |
| `COLLABORA_*` | Online editor |

DWG/DXF drawings: after the first `compose up`, run `./scripts/set-cad.sh` (copying files is not enough). Details and pitfalls: [cad.md](cad.md).

## Basic Nextcloud setup

```bash
./scripts/set-basics.sh
```

The script sets HTTPS overwrite, a 1 GB quota, region `RU`, the background-job window, and mail. It also repairs indexes and bigint in filecache.

## Theming

Logo: `theming/logo.svg`. Name: `THEMING_NAME` in `.env`.

```bash
./scripts/set-theming.sh
```

## CSP / login requires a reload

If the page must be reloaded after the password (`form-action 'self'`), `files/config/config.php` must contain:

```php
'overwriteprotocol' => 'https',
```

`set-basics.sh` already sets this through `occ`.

# Troubleshooting

## Login does not work on the first try

CSP error `form-action 'self'`. Set `overwriteprotocol=https` (`./scripts/set-basics.sh`) and confirm nginx sends `X-Forwarded-Proto`.

## SMB share is empty or “storage not available”

1. The container must have the modules: `docker exec $DOCKER_CONTAINER_NAME php -m | grep smb`
2. If they are missing, the image was not built from the `Dockerfile`. Run `./scripts/rebuild-image.sh`
3. For a share that uses the user’s login, a CLI check will not work — sign in through the web UI

## Collabora does not open a document

- `curl -sk https://collabora.example.com/hosting/discovery` must return XML
- `occ richdocuments:activate-config` with no errors
- In `.env`, `COLLABORA_WOPI_HOST` matches the cloud hostname
- nginx proxies `/browser`, `/cool`, `/hosting` with WebSocket
- After a Collabora image change: `./collabora/apply-caps.sh`
- If File Viewer opened instead of Collabora: `occ files_cad:configure-fileviewer`

## Nextcloud is in maintenance

```bash
docker exec -u 33 "$DOCKER_CONTAINER_NAME" php occ maintenance:mode --off
```

## DWG: “Save file” dialog or a grey icon

This is not a “corrupt file”. Nextcloud core does not know `.dwg` until the CAD deploy is done. Full write-up: [cad.md](cad.md).

Quick check (use the container name from `.env`):

```bash
set -a && source .env && set +a
docker exec "$DOCKER_CONTAINER_NAME" test -f /var/www/html/custom_apps/files_cad/appinfo/info.xml && echo app_mounted
docker exec -u 33 "$DOCKER_CONTAINER_NAME" php occ app:list | grep -E 'files_cad|fileviewer'
docker exec "$DOCKER_CONTAINER_NAME" test -f /var/www/html/core/img/filetypes/application-dwg.svg && echo icon_ok
```

| Symptom | What to do |
|---|---|
| No `app_mounted` | `docker compose up -d nextcloud` — the `./apps/files_cad` volume is not attached |
| No `files_cad` / `fileviewer` in app:list | `./scripts/set-cad.sh` |
| Icon still grey after the script | Ctrl+F5; run `occ maintenance:mimetype:update-js` again |
| Click still says “Save” | `occ maintenance:mimetype:update-db --repair-filecache` — old files (and SMB) stayed `octet-stream` |
| docx opened outside Collabora | `occ files_cad:configure-fileviewer` |
| No `dwg2SVG`, but the drawing opens | Expected. The converter is only for thumbnails: `./scripts/rebuild-image.sh` |
| Floor plan looks messy at full view | Normal dense DWG. Zoom, layers, PDF. Do not “fix” the deploy |

Do not copy the app into `files/apps`. Do not edit `mimetypemapping.dist.json`.

After `occ upgrade`, core overwrites `files/core/img/filetypes` and `mimetypelist.js` — run `./scripts/set-cad.sh` again and Ctrl+F5.

## Container killed by OOM

Nextcloud is limited to 1 GiB, Collabora to 2 GiB. Check `docker inspect` → `OOMKilled`. Do not lift the limits on a 6 GiB RAM host.

## Database will not connect

The Postgres container must be on `docker-lan`. The hostname must match `POSTGRES_HOST`. Check from Nextcloud:

```bash
docker exec "$DOCKER_CONTAINER_NAME" php -r \
  'new PDO("pgsql:host=postgres;dbname=nextcloud","nextcloud","PASSWORD"); echo "ok\n";'
```

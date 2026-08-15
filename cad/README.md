# Drawing MIME types

Extensions and icon aliases for construction files. `scripts/set-cad.sh` merges them into `files/config/`.

Do not write the same mapping into `files/resources/config/mimetypemapping.dist.json` — a Nextcloud upgrade overwrites that file.

After you copy this onto a new host, these are mandatory:

```bash
occ maintenance:mimetype:update-db --repair-filecache
occ maintenance:mimetype:update-js
```

Otherwise existing `.dwg` files (including on SMB) stay `application/octet-stream`.

Full write-up: [docs/cad.md](../docs/cad.md).

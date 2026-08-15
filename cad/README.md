# MIME чертежей

Расширения и алиасы иконок для строительных файлов. `scripts/set-cad.sh` мержит их в `files/config/`.

Не писать то же самое в `files/resources/config/mimetypemapping.dist.json` — файл затрёт обновление Nextcloud.

После копирования на новый хост обязательны:

```bash
occ maintenance:mimetype:update-db --repair-filecache
occ maintenance:mimetype:update-js
```

Иначе уже лежащие `.dwg` (в том числе на SMB) останутся `application/octet-stream`.

Полный разбор: [docs/cad.md](../docs/cad.md).

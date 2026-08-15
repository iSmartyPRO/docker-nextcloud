# files_cad

Приложение Nextcloud для строительных чертежей: превью DWG / DXF и запасной SVG-просмотр.

Клик по файлу в браузере даёт Universal File Viewer (`fileviewer`). Это приложение его не заменяет, а:

- регистрирует превью через LibreDWG;
- открывает `/apps/files_cad/view` как запасной экран;
- командой `occ files_cad:configure-fileviewer` оставляет File Viewer только на CAD / BIM, чтобы офис остался в Collabora.

Включается так:

```bash
./scripts/set-cad.sh
```

Без `occ` (enable + MIME repair) клик по DWG предлагает сохранить файл.

Деплой на новый хост и ловушки: [docs/cad.md](../../docs/cad.md). Не копировать приложение в `files/apps`.

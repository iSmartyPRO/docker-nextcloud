#!/usr/bin/env bash
# Enable DWG/DXF viewing for construction drawings.
# fileviewer = click-to-open in the browser; files_cad = fallback viewer + previews.
# Office documents stay on Collabora.
source "$(dirname "$0")/lib/common.sh"

OCC=(docker exec -u 33 "$DOCKER_CONTAINER_NAME" php occ)

if ! docker exec "$DOCKER_CONTAINER_NAME" test -f /var/www/html/custom_apps/files_cad/appinfo/info.xml; then
  echo "Приложение files_cad не смонтировано. Пересоздаю контейнер..."
  docker compose up -d nextcloud
  sleep 3
fi

if ! docker exec "$DOCKER_CONTAINER_NAME" test -f /var/www/html/custom_apps/files_cad/appinfo/info.xml; then
  echo "files_cad так и не появился в custom_apps. Проверьте том в docker-compose.yml." >&2
  exit 1
fi

echo "Включение приложения files_cad..."
"${OCC[@]}" app:enable files_cad

echo "Установка Universal File Viewer (просмотр DWG в браузере)..."
"${OCC[@]}" app:install fileviewer || true
"${OCC[@]}" app:enable fileviewer || true

if "${OCC[@]}" app:list | grep -q 'fileviewer'; then
  echo "fileviewer только для CAD/BIM, офис остаётся в Collabora..."
  "${OCC[@]}" files_cad:configure-fileviewer || true
else
  echo "fileviewer не установился — клик по DWG откроет запасной просмотр files_cad."
fi

echo "MIME-типы DWG/DXF..."
python3 - <<'PY'
import json
from pathlib import Path

root = Path("files/config")
root.mkdir(parents=True, exist_ok=True)

def merge(name: str, extra_path: str) -> None:
    dest = root / name
    extra = json.loads(Path(extra_path).read_text())
    current = {}
    if dest.exists() and dest.stat().st_size:
        try:
            current = json.loads(dest.read_text())
        except json.JSONDecodeError:
            current = {}
    if not isinstance(current, dict):
        current = {}
    current.update(extra)
    dest.write_text(json.dumps(current, indent=2, ensure_ascii=False) + "\n")

merge("mimetypemapping.json", "cad/mimetypemapping.json")
merge("mimetypealiases.json", "cad/mimetypealiases.json")
print("MIME mappings updated")
PY

ICON_DIR="files/core/img/filetypes"
if [[ -d "$ICON_DIR" ]]; then
  cp -f apps/files_cad/img/filetypes/application-dwg.svg "$ICON_DIR/application-dwg.svg"
  cp -f apps/files_cad/img/filetypes/application-dwg.svg "$ICON_DIR/application-cad.svg"
  cp -f apps/files_cad/img/filetypes/application-dwg.svg "$ICON_DIR/application-acad.svg"
  cp -f apps/files_cad/img/filetypes/application-dwg.svg "$ICON_DIR/application-x-dwg.svg"
  cp -f apps/files_cad/img/filetypes/application-dwg.svg "$ICON_DIR/image-vnd-dwg.svg"
  cp -f apps/files_cad/img/filetypes/application-dxf.svg "$ICON_DIR/application-dxf.svg"
  cp -f apps/files_cad/img/filetypes/application-dxf.svg "$ICON_DIR/application-x-dxf.svg"
  cp -f apps/files_cad/img/filetypes/application-dxf.svg "$ICON_DIR/image-vnd-dxf.svg"
fi

"${OCC[@]}" maintenance:mimetype:update-db --repair-filecache
"${OCC[@]}" maintenance:mimetype:update-js || true

if docker exec "$DOCKER_CONTAINER_NAME" sh -c 'command -v dwg2SVG >/dev/null || command -v dwg2svg >/dev/null'; then
  echo "LibreDWG есть — превью DWG в списке файлов включены."
else
  echo "LibreDWG в образе нет: просмотр в браузере работает, миниатюры появятся после ./scripts/rebuild-image.sh"
fi

echo
echo "CAD настроен. Обновите страницу облака (Ctrl+F5) и снова откройте .dwg."

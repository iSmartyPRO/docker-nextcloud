# Чертежи CAD (DWG / DXF)

Облако хранит, расшаривает и **открывает в браузере** строительные чертежи AutoCAD. Редактор документов — Collabora: офисные файлы CAD-просмотрщик не перехватывает.

Полный деплой стека: [deploy.md](deploy.md). Эта страница — обязательное чтение перед включением DWG на **новом компьютере**. Без шагов ниже клик по `.dwg` даёт окно «Сохранить файл», иконка остаётся серой.

---

## Что получает пользователь

| Действие | Как |
|---|---|
| Загрузить `.dwg` / `.dxf` / `.dwf` | Как любой файл, в том числе с SMB-шары |
| Узнать DWG в списке | Красная «A» AutoCAD и подпись DWG; DXF — жёлтая |
| Открыть чертёж | Клик → просмотр в браузере (не диалог сохранения) |
| Превью-миниатюра | Только если в образе есть LibreDWG (`dwg2SVG`) |
| Редактировать | Скачать → AutoCAD / nanoCAD / КОМПАС |
| IFC (BIM) | Тот же browser-viewer |

Collabora / LibreOffice для DWG **не** использовать: импорт чертежей там слабый.

---

## Состав

| Компонент | Где | Роль |
|---|---|---|
| `fileviewer` (Universal File Viewer) | App Store, ставит `set-cad.sh` | Клик по DWG/DXF: WebGL в браузере |
| `files_cad` | репозиторий `apps/files_cad` | MIME, иконки, запасной просмотр, `occ files_cad:configure-fileviewer` |
| `cad/mimetypemapping.json` | репозиторий | Расширения → MIME |
| `cad/mimetypealiases.json` | репозиторий | MIME → имя иконки |
| LibreDWG + `rsvg-convert` | образ `cloud-nextcloud:local` | Миниатюры в списке, не сам просмотр |
| Collabora | как раньше | docx / xlsx / pptx |

Исходник приложения в git — **`apps/files_cad`**. Каталог `files/` в git не входит.

---

## Деплой на другом компьютере (обязательный порядок)

Корень репозитория = `$ROOT`. Сначала поднять стек по [deploy.md](deploy.md) сценарий A до `installed: true`, затем:

```bash
cd "$ROOT"
set -a && source .env && set +a
NC="$DOCKER_CONTAINER_NAME"
OCC="docker exec -u 33 $NC php occ"
```

### 1. Контейнер должен видеть приложение

В `docker-compose.yml` есть том:

```yaml
- ./apps/files_cad:/var/www/html/custom_apps/files_cad:ro
```

После `git clone` / правки compose **пересоздать** контейнер, иначе том не подключится (старый контейнер живёт со старыми mounts):

```bash
docker compose up -d nextcloud
docker exec "$NC" test -f /var/www/html/custom_apps/files_cad/appinfo/info.xml && echo OK
```

Если `OK` нет — остановиться. Не копировать приложение в `files/apps` (сотрётся при `occ upgrade`).

### 2. Включить CAD (не пропускать)

Положить файлы на диск **мало**. Nextcloud не откроет DWG, пока не выполнятся `occ`:

```bash
./scripts/set-cad.sh
```

Скрипт делает всё ниже. Если его нет под рукой — те же шаги вручную:

```bash
$OCC app:enable files_cad
$OCC app:install fileviewer || true
$OCC app:enable fileviewer
$OCC files_cad:configure-fileviewer
# MIME из репозитория → files/config/
# иконки → files/core/img/filetypes/
$OCC maintenance:mimetype:update-db --repair-filecache
$OCC maintenance:mimetype:update-js
```

`fileviewer` качается с App Store — на хосте нужен выход в интернет. Нужен Nextcloud **33+** (этот стек — 34).

Владелец файлов приложения, если копировали руками: UID **33** (`www-data`), не root.

```bash
chown -R 33:33 files/custom_apps/files_cad \
  files/config/mimetypemapping.json \
  files/config/mimetypealiases.json
```

### 3. Проверка в браузере

1. Жёсткое обновление: **Ctrl+F5** (иначе кэш старого `mimetypelist.js` и серая иконка).
2. Открыть папку с `.dwg` (локальную или SMB).
3. Иконка — красная «A» + DWG, не серый документ.
4. Клик открывает чертёж, не «Сохранить файл».
5. Открыть docx — должен быть Collabora, не File Viewer.

```bash
$OCC app:list | grep -E 'files_cad|fileviewer|richdocuments'
docker exec "$NC" test -f /var/www/html/core/img/filetypes/application-dwg.svg && echo icons_ok
```

Миниатюра в списке — необязательна. Для неё:

```bash
./scripts/rebuild-image.sh
docker exec "$NC" sh -c 'command -v dwg2SVG || command -v dwg2svg'
```

Просмотр кликом от LibreDWG **не** зависит.

---

## Ловушки (уже ловили на стенде)

Зафиксировано на живом инстансе. На новом хосте повторять те же ошибки не нужно.

### Клик по DWG открывает «Сохранить файл»

Ядро Nextcloud **не знает** расширение `.dwg`. Без наших MIME файл в `oc_filecache` остаётся `application/octet-stream`. Для «неизвестного» бинарника UI всегда предлагает скачать.

Нужны **все** пункты:

1. `files/config/mimetypemapping.json` — `"dwg": ["image/vnd.dwg"]` (не править `resources/config/mimetypemapping.dist.json`: его затрёт обновление ядра).
2. `$OCC maintenance:mimetype:update-db --repair-filecache` — иначе **уже лежащие** DWG (в том числе на SMB) остаются со старым MIME. На стенде после команды было: `Updated 2 filecache rows for mimetype "image/vnd.dwg"`.
3. Включён `files_cad` **и/или** `fileviewer`. Файлы в `custom_apps/files_cad` без `app:enable` не работают.
4. Ctrl+F5 после смены MIME.

Проверка типа конкретного файла (имя подставить своё):

```bash
$OCC files:scan --path="<user>/files/..."   # только если filecache точно устарел
```

Или смотреть MIME в веб: свойства файла. Должно быть `image/vnd.dwg` / AutoCAD drawing, не «Unknown».

### Серая иконка вместо AutoCAD

Иконка берётся не из расширения, а из цепочки MIME → alias → SVG → JS-список.

| Кусок | Куда | Имя |
|---|---|---|
| Alias | `files/config/mimetypealiases.json` | `image/vnd.dwg` → `application-dwg` |
| Картинка | `files/core/img/filetypes/application-dwg.svg` | красная «A» + DWG |
| Список для браузера | `files/core/js/mimetypelist.js` | только через `$OCC maintenance:mimetype:update-js` |

Править `mimetypelist.js` руками не нужно — `update-js` пересоберёт. После обновления ядра Nextcloud каталог `files/core/` перезаписывается: иконки и JS снова серые, пока не выполнить `./scripts/set-cad.sh`.

Исходники иконок в git: `apps/files_cad/img/filetypes/`.

### Том в compose есть, а приложения в контейнере нет

`docker compose.yml` поменяли, контейнер **не** пересоздавали — bind-mount старый. Симптом: `test -f .../custom_apps/files_cad/appinfo/info.xml` падает.

```bash
docker compose up -d nextcloud
```

Не лечить копированием в `files/apps`.

На уже работающем стенде допустим запасной путь: положить копию в `files/custom_apps/files_cad` (это bind-mount `./files`). После следующего `compose up` с томом из `apps/files_cad` победит git-версия — так и должно быть.

### `set-cad.sh` не запускали

Код в репозитории ≠ включённый просмотр. Пока нет `files_cad 1.0.x enabled` в `occ app:list` и нет строк MIME в filecache — будет сохранение файла. Так и было, пока на стенде вручную не выполнили `occ`.

### File Viewer перехватывает Word / Excel

`fileviewer` из коробки умеет 200+ форматов. Сразу после `app:install`:

```bash
$OCC files_cad:configure-fileviewer
```

Иначе docx откроется в File Viewer, а не в Collabora. Повторять после `$OCC app:update --all`.

### Нет интернета на хосте

`occ app:install fileviewer` не скачает пакет. Тогда клик всё равно может открыть запасной экран `files_cad` (`/apps/files_cad/view`), но WebGL-просмотрщик не поставится. Для стройки лучше дать хосту доступ к App Store Nextcloud хотя бы на время установки.

### LibreDWG нет, а просмотр «должен» работать

`dwg2SVG` нужен только для миниатюр. Его отсутствие — не причина окна сохранения. Не блокировать деплой из-за пустого `command -v dwg2SVG`, если клик по DWG уже открывает чертёж.

Пакет вшивается в образ (`Dockerfile`). `apt install` внутри уже запущенного контейнера пропадёт при recreate — как с SMB.

### Шара SMB, файл «только для чтения»

Просмотр не требует записи. MIME чинится в `filecache` так же, как для локальных файлов. `occ files_external:verify` для шары с логином пользователя по-прежнему не доказательство поломки.

### После `occ upgrade` / `rebuild-image.sh`

1. Контейнер новый — том `apps/files_cad` должен снова быть в `docker inspect` mounts.
2. Ядро перезаписало `files/core/` — снова `./scripts/set-cad.sh`.
3. `$OCC files_cad:configure-fileviewer`.
4. Ctrl+F5.

### Плотный план этажа «тормозит» или выглядит кашей

Это не ошибка деплоя. Строительный DWG с осями, лестницами и условными знаками в браузере на общем виде так и выглядит. Приблизить колесом, выключить слои, для согласования класть PDF. Подробности — раздел «Тяжёлые чертежи» ниже.

---

## Инварианты CAD (не нарушать)

| Запрет | Почему |
|---|---|
| Не считать деплой CAD законченным после `git pull` без `set-cad.sh` | Приложения и filecache не обновятся |
| Не править `mimetypemapping.dist.json` | Затрёт обновление Nextcloud |
| Не класть `files_cad` в `files/apps` | Затрёт `occ upgrade` |
| Не ждать иконку/просмотр без `update-db --repair-filecache` | Старые DWG остаются `octet-stream` |
| Не ставить `fileviewer` и не вызывать `configure-fileviewer` | docx уйдёт из Collabora |
| Не лечить LibreDWG через `apt` в живом контейнере | Пропадёт при recreate |
| Не объявлять поломку просмотрщика, если план этажа «каша» на общем виде | Нормальный плотный DWG |

---

## Тяжёлые чертежи

Строительный план этажа — обычный плотный DWG, не битый файл. Браузерный просмотрщик не заменяет AutoCAD.

Уже достаточно для облака: открыть, показать подрядчику, скачать для правок.

Не ждите: редактирование DWG, идеальные штриховки/размеры, зум как в десктопе на генплане с xref.

Как работать быстрее:

1. Приближать колесом.
2. Выключать слои мебели, аннотаций, сетки.
3. На согласование — PDF с листа рядом с DWG.
4. Авторам: `PURGE`, без лишних xref, `PROXYGRAPHICS=1` при сохранении.

Лимиты запасного SVG-конвертера (если нет fileviewer): превью 16 МиБ, просмотр 64 МиБ, контейнер Nextcloud 1 GiB. File Viewer считает чертёж в браузере и сервер почти не грузит.

---

## Команды на уже живом инстансе

Повторить настройку (безопасно, идемпотентно):

```bash
./scripts/set-cad.sh
```

Только не дать fileviewer забрать офис:

```bash
docker exec -u 33 "$DOCKER_CONTAINER_NAME" php occ files_cad:configure-fileviewer
```

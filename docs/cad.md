# CAD drawings (DWG / DXF)

The cloud stores, shares, and **opens in the browser** AutoCAD construction drawings. The document editor is Collabora: the CAD viewer does not intercept office files.

Full stack deploy: [deploy.md](deploy.md). Read this page before you enable DWG on a **new machine**. Without the steps below, a click on `.dwg` opens a “Save file” dialog and the icon stays grey.

---

## What the user gets

| Action | How |
|---|---|
| Upload `.dwg` / `.dxf` / `.dwf` | Like any other file, including from an SMB share |
| Recognize DWG in the list | Red AutoCAD “A” and a DWG label; DXF is yellow |
| Open a drawing | Click → view in the browser (not a save dialog) |
| List thumbnail | Only if the image has LibreDWG (`dwg2SVG`) |
| Edit | Download → AutoCAD / nanoCAD / KOMPAS |
| IFC (BIM) | Same browser viewer |

Do **not** use Collabora / LibreOffice for DWG: their drawing import is weak.

---

## Components

| Component | Where | Role |
|---|---|---|
| `fileviewer` (Universal File Viewer) | App Store, installed by `set-cad.sh` | Click DWG/DXF: WebGL in the browser |
| `files_cad` | repository `apps/files_cad` | MIME, icons, fallback viewer, `occ files_cad:configure-fileviewer` |
| `cad/mimetypemapping.json` | repository | Extension → MIME |
| `cad/mimetypealiases.json` | repository | MIME → icon name |
| LibreDWG + `rsvg-convert` | image `cloud-nextcloud:local` | List thumbnails, not the viewer itself |
| Collabora | as before | docx / xlsx / pptx |

The app source in git is **`apps/files_cad`**. The `files/` directory is not in git.

---

## Deploy on another machine (required order)

Repository root = `$ROOT`. First bring the stack up with [deploy.md](deploy.md) scenario A until `installed: true`, then:

```bash
cd "$ROOT"
set -a && source .env && set +a
NC="$DOCKER_CONTAINER_NAME"
OCC="docker exec -u 33 $NC php occ"
```

### 1. The container must see the app

`docker-compose.yml` has this volume:

```yaml
- ./apps/files_cad:/var/www/html/custom_apps/files_cad:ro
```

After `git clone` or a compose edit, **recreate** the container. Otherwise the volume does not attach (the old container keeps old mounts):

```bash
docker compose up -d nextcloud
docker exec "$NC" test -f /var/www/html/custom_apps/files_cad/appinfo/info.xml && echo OK
```

If there is no `OK` — stop. Do not copy the app into `files/apps` (`occ upgrade` will wipe it).

### 2. Enable CAD (do not skip)

Putting files on disk is **not enough**. Nextcloud will not open DWG until these `occ` steps run:

```bash
./scripts/set-cad.sh
```

The script does everything below. If you do not have it, the same steps by hand:

```bash
$OCC app:enable files_cad
$OCC app:install fileviewer || true
$OCC app:enable fileviewer
$OCC files_cad:configure-fileviewer
# MIME from the repo → files/config/
# icons → files/core/img/filetypes/
$OCC maintenance:mimetype:update-db --repair-filecache
$OCC maintenance:mimetype:update-js
```

`fileviewer` is downloaded from the App Store — the host needs outbound internet. Nextcloud **33+** is required (this stack is 34).

If you copied app files by hand, the owner is UID **33** (`www-data`), not root.

```bash
chown -R 33:33 files/custom_apps/files_cad \
  files/config/mimetypemapping.json \
  files/config/mimetypealiases.json
```

### 3. Check in the browser

1. Hard refresh: **Ctrl+F5** (otherwise a cached `mimetypelist.js` and a grey icon).
2. Open a folder with a `.dwg` (local or SMB).
3. The icon is a red “A” + DWG, not a grey document.
4. A click opens the drawing, not “Save file”.
5. Open a docx — it must be Collabora, not File Viewer.

```bash
$OCC app:list | grep -E 'files_cad|fileviewer|richdocuments'
docker exec "$NC" test -f /var/www/html/core/img/filetypes/application-dwg.svg && echo icons_ok
```

A list thumbnail is optional. For thumbnails:

```bash
./scripts/rebuild-image.sh
docker exec "$NC" sh -c 'command -v dwg2SVG || command -v dwg2svg'
```

Click-to-view does **not** depend on LibreDWG.

---

## Pitfalls (already seen on a live instance)

Recorded on a running instance. A new host does not need to repeat the same mistakes.

### A click on DWG opens “Save file”

Nextcloud core **does not know** the `.dwg` extension. Without our MIME mapping the file stays `application/octet-stream` in `oc_filecache`. For an “unknown” binary the UI always offers a download.

You need **all** of these:

1. `files/config/mimetypemapping.json` — `"dwg": ["image/vnd.dwg"]` (do not edit `resources/config/mimetypemapping.dist.json`: a core upgrade overwrites it).
2. `$OCC maintenance:mimetype:update-db --repair-filecache` — otherwise **already stored** DWG files (including on SMB) keep the old MIME. On the lab host the command reported: `Updated 2 filecache rows for mimetype "image/vnd.dwg"`.
3. `files_cad` **and/or** `fileviewer` enabled. Files in `custom_apps/files_cad` do nothing without `app:enable`.
4. Ctrl+F5 after a MIME change.

Check a specific file (substitute the name):

```bash
$OCC files:scan --path="<user>/files/..."   # only if filecache is definitely stale
```

Or look at MIME in the web UI: file properties. It must be `image/vnd.dwg` / AutoCAD drawing, not “Unknown”.

### Grey icon instead of AutoCAD

The icon comes from the chain MIME → alias → SVG → JS list, not from the extension.

| Piece | Where | Name |
|---|---|---|
| Alias | `files/config/mimetypealiases.json` | `image/vnd.dwg` → `application-dwg` |
| Image | `files/core/img/filetypes/application-dwg.svg` | red “A” + DWG |
| Browser list | `files/core/js/mimetypelist.js` | only via `$OCC maintenance:mimetype:update-js` |

Do not edit `mimetypelist.js` by hand — `update-js` rebuilds it. After a Nextcloud core upgrade, `files/core/` is overwritten: icons and JS go grey again until you run `./scripts/set-cad.sh`.

Icon sources in git: `apps/files_cad/img/filetypes/`.

### Compose has the volume, the container does not have the app

`docker-compose.yml` changed, the container was **not** recreated — the bind-mount is old. Symptom: `test -f .../custom_apps/files_cad/appinfo/info.xml` fails.

```bash
docker compose up -d nextcloud
```

Do not “fix” it by copying into `files/apps`.

On an already running host a fallback is allowed: put a copy in `files/custom_apps/files_cad` (that is the `./files` bind-mount). After the next `compose up` with the `apps/files_cad` volume, the git version wins — that is intended.

### `set-cad.sh` was not run

Code in the repository ≠ viewing enabled. Until `files_cad 1.0.x enabled` is in `occ app:list` and MIME rows exist in filecache, the UI will save the file. That is exactly what happened until `occ` was run by hand on the lab host.

### File Viewer intercepts Word / Excel

Out of the box `fileviewer` handles 200+ formats. Right after `app:install`:

```bash
$OCC files_cad:configure-fileviewer
```

Otherwise a docx opens in File Viewer, not Collabora. Repeat after `$OCC app:update --all`.

### No internet on the host

`occ app:install fileviewer` will not download the package. A click may still open the `files_cad` fallback (`/apps/files_cad/view`), but the WebGL viewer will not be installed. For a construction site, give the host App Store access at least for the install.

### LibreDWG is missing, but viewing “should” work

`dwg2SVG` is only for thumbnails. Its absence is not why the save dialog appears. Do not block the deploy because `command -v dwg2SVG` is empty if a DWG click already opens the drawing.

The package is baked into the image (`Dockerfile`). `apt install` inside an already running container disappears on recreate — same as SMB.

### SMB share, file is “read only”

Viewing does not need write access. MIME is repaired in `filecache` the same way as for local files. `occ files_external:verify` on a share with user login is still not proof of a break.

### After `occ upgrade` / `rebuild-image.sh`

1. New container — the `apps/files_cad` volume must show up again in `docker inspect` mounts.
2. Core overwrote `files/core/` — run `./scripts/set-cad.sh` again.
3. `$OCC files_cad:configure-fileviewer`.
4. Ctrl+F5.

### A dense floor plan is “slow” or looks like a mess

This is not a deploy bug. A construction DWG with axes, stairs, and symbols looks like that in a browser at full view. Zoom with the wheel, turn layers off, put a PDF next to it for review. Details: “Heavy drawings” below.

---

## CAD invariants (do not break)

| Do not | Why |
|---|---|
| Do not treat CAD as done after `git pull` without `set-cad.sh` | Apps and filecache will not update |
| Do not edit `mimetypemapping.dist.json` | A Nextcloud upgrade overwrites it |
| Do not put `files_cad` in `files/apps` | `occ upgrade` overwrites it |
| Do not wait for an icon/viewer without `update-db --repair-filecache` | Old DWG files stay `octet-stream` |
| Do not install `fileviewer` and skip `configure-fileviewer` | docx leaves Collabora |
| Do not “fix” LibreDWG with `apt` in a live container | It disappears on recreate |
| Do not call the viewer broken if a floor plan looks messy at full view | Normal dense DWG |

---

## Heavy drawings

A construction floor plan is a normal dense DWG, not a corrupt file. The browser viewer does not replace AutoCAD.

Already enough for the cloud: open, show a contractor, download for edits.

Do not expect: DWG editing, perfect hatches/dimensions, desktop-class zoom on a site plan with xrefs.

Work faster:

1. Zoom with the wheel.
2. Turn off furniture, annotation, and grid layers.
3. For review — a sheet PDF next to the DWG.
4. For authors: `PURGE`, no extra xrefs, `PROXYGRAPHICS=1` on save.

Fallback SVG converter limits (if fileviewer is missing): preview 16 MiB, view 64 MiB, Nextcloud container 1 GiB. File Viewer renders in the browser and barely loads the server.

---

## Commands on a live instance

Repeat setup (safe, idempotent):

```bash
./scripts/set-cad.sh
```

Only keep fileviewer off office files:

```bash
docker exec -u 33 "$DOCKER_CONTAINER_NAME" php occ files_cad:configure-fileviewer
```

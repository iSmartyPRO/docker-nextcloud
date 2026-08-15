# files_cad

A Nextcloud app for construction drawings: DWG / DXF thumbnails and a fallback SVG viewer.

Click-to-open in the browser is Universal File Viewer (`fileviewer`). This app does not replace it. It:

- registers previews through LibreDWG;
- opens `/apps/files_cad/view` as a fallback screen;
- keeps File Viewer on CAD / BIM only via `occ files_cad:configure-fileviewer`, so office files stay in Collabora.

Enable it with:

```bash
./scripts/set-cad.sh
```

Without `occ` (enable + MIME repair), a click on DWG offers to save the file.

Deploy on a new host and pitfalls: [docs/cad.md](../../docs/cad.md). Do not copy this app into `files/apps`.

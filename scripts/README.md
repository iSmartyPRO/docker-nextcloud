# Scripts

Run from any directory. Shared `.env` loader: [`lib/common.sh`](lib/common.sh).

`occ` inside the scripts always runs as UID 33 (`www-data`).

| Script | When |
|---|---|
| `set-basics.sh` | First start: HTTPS, quota, mail, indexes |
| `set-theming.sh` | Theme and logo |
| `set-ldap.sh` | Write LDAP / AD |
| `test-ldap.sh` | LDAP check without writing |
| `set-collabora.sh` | Bind Collabora |
| `set-cad.sh` | Every new host and after `occ upgrade` |
| `apps-enable.sh` | LDAP + external storage |
| `apps-disable.sh` | Only when explicitly asked: turns off many stock apps |
| `rebuild-image.sh` | After the base `nextcloud:latest` changes |
| `apps-list.sh` | List apps |
| `background-job.sh` | Background-job window |

Drawings: without `set-cad.sh`, a click on `.dwg` offers to save the file. Write-up: [docs/cad.md](../docs/cad.md).

Operations: [docs/operations.md](../docs/operations.md).

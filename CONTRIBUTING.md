# Contributing

This repository is a working stack, not a kit for every use case. Changes must keep the invariants in [docs/deploy.md](docs/deploy.md).

## How to work

1. Read [docs/deploy.md](docs/deploy.md) and [docs/cad.md](docs/cad.md).
2. Do not commit `.env`, `files/`, `backups/`, or site-specific nginx configs.
3. Secrets in examples must be obvious placeholders (`change-me-…`, `example.com`).
4. Scripts run from any directory. The shared loader is `scripts/lib/common.sh`.
5. `occ` only as UID 33 (`www-data`).

## Do not change without a reason

- Application image: `build` from the `Dockerfile`, tag `cloud-nextcloud:local`. Do not switch to a plain `nextcloud:latest`.
- Network: external `docker-lan`. Compose does not create it.
- CAD: MIME only in `files/config/`. The app lives in `custom_apps` via the `./apps/files_cad` volume.
- Document editor is Collabora. Do not bring OnlyOffice back.

## Documentation

Write in English. Tone is a runbook for an operator. Commands must be copy-pasteable. If a step is dangerous, say why — not “just in case”.

Add a new page to [docs/README.md](docs/README.md). If it is a deploy scenario, add it to the verification matrix in [docs/deploy.md](docs/deploy.md).

## Before a pull request

- `docker compose config` succeeds with a filled `.env`.
- The script you touched is idempotent: a second run does not break a live instance.
- After CAD or core changes, the runbook still calls `./scripts/set-cad.sh`.

# Documentation

Corporate file cloud on Nextcloud: LDAP / Active Directory, SMB, Collabora Online, PostgreSQL, and in-browser DWG / DXF viewing.

Pick a scenario in [deploy.md](deploy.md) first. The other pages are details, not a second runbook.

## Start here

| Page | Contents |
|---|---|
| [deploy.md](deploy.md) | New host, upgrade, move, database change. Verification matrix |
| [install.md](install.md) | Requirements, `docker-lan`, first `compose up` |
| [configuration.md](configuration.md) | `.env`, basics, theming, mail, CSP |

## Integrations

| Page | Contents |
|---|---|
| [ldap.md](ldap.md) | Sign-in through Active Directory |
| [smb.md](smb.md) | External SMB / CIFS shares |
| [collabora.md](collabora.md) | Online document editor |
| [cad.md](cad.md) | DWG / DXF: MIME, icons, pitfalls, heavy drawings |
| [nginx.md](nginx.md) | Reverse proxy and TLS |
| [database.md](database.md) | PostgreSQL and MariaDB migration |

## Operations

| Page | Contents |
|---|---|
| [operations.md](operations.md) | occ, apps, upgrades, backup |
| [troubleshooting.md](troubleshooting.md) | Common errors and what not to “fix” |

## Order on a new host

1. [install.md](install.md) — network, `.env`, build, start.
2. [deploy.md](deploy.md) scenario A — setup scripts.
3. [cad.md](cad.md) — `./scripts/set-cad.sh` is mandatory, then Ctrl+F5.
4. [troubleshooting.md](troubleshooting.md) — only if the verification matrix is red.

# Документация

Корпоративное файловое облако на Nextcloud: LDAP / Active Directory, SMB, Collabora Online, PostgreSQL и просмотр чертежей DWG / DXF.

Сначала выберите сценарий в [deploy.md](deploy.md). Остальные страницы — уточнения, а не второй runbook.

## Старт

| Страница | Содержание |
|---|---|
| [deploy.md](deploy.md) | Новый сервер, обновление, перенос, смена СУБД. Матрица проверки |
| [install.md](install.md) | Требования, сеть `docker-lan`, первый `compose up` |
| [configuration.md](configuration.md) | `.env`, базовая настройка, тема, почта, CSP |

## Интеграции

| Страница | Содержание |
|---|---|
| [ldap.md](ldap.md) | Вход через Active Directory |
| [smb.md](smb.md) | Внешние шары SMB / CIFS |
| [collabora.md](collabora.md) | Онлайн-редактор документов |
| [cad.md](cad.md) | DWG / DXF: MIME, иконки, ловушки, тяжёлые чертежи |
| [nginx.md](nginx.md) | Reverse proxy и TLS |
| [database.md](database.md) | PostgreSQL и миграция с MariaDB |

## Эксплуатация

| Страница | Содержание |
|---|---|
| [operations.md](operations.md) | occ, приложения, обновление, бэкап |
| [troubleshooting.md](troubleshooting.md) | Частые ошибки и что не чинить |

## Порядок на новом хосте

1. [install.md](install.md) — сеть, `.env`, сборка, старт.
2. [deploy.md](deploy.md) сценарий A — скрипты настройки.
3. [cad.md](cad.md) — обязательно `./scripts/set-cad.sh` и Ctrl+F5.
4. [troubleshooting.md](troubleshooting.md) — только если матрица проверки красная.

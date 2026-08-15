<div align="center">

# docker-nextcloud

**Корпоративное файловое облако на Nextcloud**

Active Directory · SMB · Collabora Online · PostgreSQL · DWG / DXF

[![Nextcloud](https://img.shields.io/badge/Nextcloud-34-0082c9?style=flat-square&logo=nextcloud&logoColor=white)](https://nextcloud.com)
[![Docker](https://img.shields.io/badge/Docker-Compose_v2-2496ed?style=flat-square&logo=docker&logoColor=white)](https://docs.docker.com/compose/)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-14–18-4169e1?style=flat-square&logo=postgresql&logoColor=white)](https://www.postgresql.org)
[![Collabora](https://img.shields.io/badge/Collabora-Online-5c2d91?style=flat-square)](https://www.collaboraoffice.com)
[![License](https://img.shields.io/badge/License-AGPL--3.0-red?style=flat-square)](LICENSE)

[Документация](docs/README.md) · [Деплой](docs/deploy.md) · [Чертежи CAD](docs/cad.md) · [Безопасность](SECURITY.md)

</div>

---

Стек для компании, которой нужно одно место для файлов, офисных документов и строительных чертежей. Пользователи входят через Active Directory, шары SMB открываются как обычные папки, Word и Excel правятся в браузере, DWG открывается кликом — без диалога «Сохранить файл».

Образ Nextcloud собирается из [`Dockerfile`](Dockerfile): в него вшиты SMB-клиент и LibreDWG. Голый `nextcloud:latest` для этого стека не подходит.

## Возможности

| | |
|---|---|
| **Каталог и доступ** | LDAP / Active Directory, внешние шары SMB/CIFS, квоты, HTTPS за reverse proxy |
| **Документы** | Collabora Online для DOCX, XLSX, PPTX. OnlyOffice в стеке нет |
| **Чертежи** | Просмотр DWG / DXF / DWF / IFC в браузере, иконки AutoCAD, миниатюры через LibreDWG |
| **Данные** | Внешний PostgreSQL 14–18, Redis для кэша и блокировок |
| **Эксплуатация** | Идемпотентные `occ`-обёртки, runbook на новый сервер, обновление и перенос |

## Архитектура

```mermaid
flowchart LR
  U[Браузер] --> NGX[Nginx · TLS]

  NGX --> NC[Nextcloud]
  NGX --> CO[Collabora CODE]

  NC --> RD[(Redis)]
  NC --> PG[(PostgreSQL)]
  NC --> AD[Active Directory]
  NC --> SMB[SMB / CIFS]
  NC --> CAD[files_cad + File Viewer]
```

| Сервис | Образ | Роль |
|---|---|---|
| Nextcloud | `cloud-nextcloud:local` | Файлы, LDAP, SMB, MIME и превью DWG |
| Redis | `redis:alpine` | Кэш и блокировки файлов |
| Collabora | `collabora/code` | Онлайн-редактор документов |
| PostgreSQL | внешний, сеть `docker-lan` | Единственная СУБД стека |

Nginx и SSL в этот репозиторий не входят — только образцы в [`nginx/`](nginx/).

## Быстрый старт

Нужны Docker 24+, Compose v2, сеть `docker-lan` и PostgreSQL 14–18. Для Nextcloud вместе с Collabora удобно иметь от 6 GiB RAM.

```bash
docker network create docker-lan   # если сети ещё нет
cp .env.sample .env                # заполните значения, не оставляйте sample
docker compose build
docker compose up -d
./scripts/set-basics.sh
```

Дальше — по порядку, без пропусков:

```bash
./scripts/set-theming.sh
./scripts/apps-enable.sh
./scripts/set-ldap.sh
./scripts/set-collabora.sh
./scripts/set-cad.sh               # иначе .dwg скачается как неизвестный файл
```

Полный runbook: [docs/deploy.md](docs/deploy.md). Ловушки DWG: [docs/cad.md](docs/cad.md).

## Репозиторий

```
├── docker-compose.yml
├── Dockerfile                 # Nextcloud + SMB + LibreDWG
├── .env.sample                # секреты только в локальном .env
├── docs/                      # документация и runbook
├── nginx/                     # образцы reverse proxy
├── collabora/                 # jail-patch для CODE
├── apps/files_cad/            # превью и запасной просмотр DWG/DXF
├── cad/                       # MIME-типы чертежей
├── scripts/                   # occ-обёртки
├── theming/                   # логотип
└── files/                     # данные инстанса, не в git
```

В git не попадают `.env`, `files/`, `backups/` и стендовые vhost’ы nginx.

## Скрипты

| Скрипт | Назначение |
|---|---|
| `scripts/set-basics.sh` | HTTPS, квота, почта, индексы |
| `scripts/set-theming.sh` | Название, слоган, цвет, логотип |
| `scripts/set-ldap.sh` | LDAP / Active Directory |
| `scripts/test-ldap.sh` | Проверка LDAP без записи настроек |
| `scripts/set-collabora.sh` | Привязка Collabora Online |
| `scripts/set-cad.sh` | Просмотр DWG / DXF |
| `scripts/apps-enable.sh` | LDAP и внешние хранилища |
| `scripts/apps-disable.sh` | Выключить лишние штатные приложения |
| `scripts/rebuild-image.sh` | Пересобрать образ со SMB и LibreDWG |
| `collabora/apply-caps.sh` | Capabilities после смены образа CODE |

## Документация

| Раздел | Когда открывать |
|---|---|
| [Обзор](docs/README.md) | Навигация по всем страницам |
| [Деплой](docs/deploy.md) | Новый сервер, обновление, перенос, смена СУБД |
| [Установка](docs/install.md) | Требования и первый запуск |
| [Конфигурация](docs/configuration.md) | Переменные `.env` |
| [CAD](docs/cad.md) | Чертежи: MIME, иконки, «Сохранить файл» |
| [Эксплуатация](docs/operations.md) | occ, бэкап, обновление |
| [Неполадки](docs/troubleshooting.md) | Типичные сбои и что не чинить |

## Безопасность

Секреты живут только в `.env` на хосте. Не коммитьте пароли, дампы и каталог `files/`. Как сообщать об уязвимости — в [SECURITY.md](SECURITY.md).

Collabora в этом стеке — **CODE** (Development Edition). Для крупного офиса нужна коммерческая лицензия Collabora Online.

## Лицензия

[GNU Affero General Public License v3.0](LICENSE) — как у Nextcloud и приложения `files_cad`.

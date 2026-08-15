# Участие

Репозиторий — рабочий стек, не конструктор «на все случаи». Правки должны сохранять инварианты из [docs/deploy.md](docs/deploy.md).

## Как работать

1. Прочитайте [docs/deploy.md](docs/deploy.md) и [docs/cad.md](docs/cad.md).
2. Не коммитьте `.env`, `files/`, `backups/` и стендовые nginx-конфиги.
3. Секреты в примерах — только очевидные заглушки (`change-me-…`, `example.com`).
4. Скрипты запускаются из любой директории: общий загрузчик — `scripts/lib/common.sh`.
5. `occ` — только от UID 33 (`www-data`).

## Что не менять без причины

- Образ приложения: `build` из `Dockerfile`, тег `cloud-nextcloud:local`. Не переходить на голый `nextcloud:latest`.
- Сеть: внешняя `docker-lan`, compose её не создаёт.
- CAD: MIME только в `files/config/`, приложение только в `custom_apps` через том `./apps/files_cad`.
- Редактор документов — Collabora. OnlyOffice в стек не возвращать.

## Документация

Тексты на русском, тон — runbook для исполнителя. Команды копируемые. Если шаг опасен — написать, почему, а не «на всякий случай».

Новую страницу добавьте в [docs/README.md](docs/README.md) и, если это сценарий деплоя, в матрицу проверки [docs/deploy.md](docs/deploy.md).

## Проверка перед pull request

- `docker compose config` собирается с заполненным `.env`.
- Скрипт, который трогали, идемпотентен: повторный запуск не ломает живой инстанс.
- После изменений CAD или ядра в runbook есть `./scripts/set-cad.sh`.

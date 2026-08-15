# Скрипты

Запускаются из любой директории. Общий загрузчик `.env`: [`lib/common.sh`](lib/common.sh).

`occ` внутри скриптов всегда идёт от UID 33 (`www-data`).

| Скрипт | Когда |
|---|---|
| `set-basics.sh` | Первый запуск: HTTPS, квота, почта, индексы |
| `set-theming.sh` | Тема и логотип |
| `set-ldap.sh` | Запись LDAP / AD |
| `test-ldap.sh` | Проверка LDAP без записи |
| `set-collabora.sh` | Привязка Collabora |
| `set-cad.sh` | Каждый новый хост и после `occ upgrade` |
| `apps-enable.sh` | LDAP + внешние хранилища |
| `apps-disable.sh` | Только по явной просьбе: гасит много штатных приложений |
| `rebuild-image.sh` | Смена базового `nextcloud:latest` |
| `apps-list.sh` | Список приложений |
| `background-job.sh` | Окно фоновых задач |

Чертежи: без `set-cad.sh` клик по `.dwg` предлагает сохранить файл. Разбор: [docs/cad.md](../docs/cad.md).

Эксплуатация: [docs/operations.md](../docs/operations.md).

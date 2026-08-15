# Конфигурация

Все секреты — только в `.env` (файл не попадает в git). Образец: `.env.sample`.

## Основные переменные

| Переменная | Назначение |
|---|---|
| `DOCKER_CONTAINER_NAME` | Имя контейнера Nextcloud |
| `DOCKER_PORT` | Порт на хосте (по умолчанию 8080) |
| `NEXTCLOUD_ADMIN_USER` / `NEXTCLOUD_ADMIN_PASSWORD` | Локальный администратор |
| `POSTGRES_HOST` / `POSTGRES_DB` / `POSTGRES_USER` / `POSTGRES_PASSWORD` | База |
| `NEXTCLOUD_URL` | Публичный HTTPS URL облака |
| `MAIL_*` | Исходящая почта |
| `LDAP_*` | Active Directory |
| `THEMING_NAME` / `THEMING_SLOGAN` / `THEMING_URL` / `THEMING_PRIMARYCOLOR` | Название, слоган, цвет, URL |
| `COLLABORA_*` | Онлайн-редактор |

Чертежи DWG/DXF: после первого `compose up` — `./scripts/set-cad.sh` (недостаточно скопировать файлы). Подробности и ловушки: [cad.md](cad.md).

## Базовая настройка Nextcloud

```bash
./scripts/set-basics.sh
```

Скрипт выставляет HTTPS overwrite, квоту 1 GB, регион `RU`, окно фоновых задач и почту. Также чинит индексы и bigint в filecache.

## Тема

Логотип: `theming/logo.svg`. Название — `THEMING_NAME` в `.env`.

```bash
./scripts/set-theming.sh
```

## CSP / повторный логин

Если после ввода пароля нужна перезагрузка страницы (`form-action 'self'`), в `files/config/config.php` должно быть:

```php
'overwriteprotocol' => 'https',
```

`set-basics.sh` уже выставляет это через `occ`.

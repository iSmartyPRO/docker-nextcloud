# SMB / внешние хранилища

Клиент SMB вшит в образ `cloud-nextcloud:local` (`Dockerfile`): пакет `smbclient` и PHP-расширение `smbclient`. Пересоздание контейнера их не стирает.

## Включение приложения

```bash
./scripts/apps-enable.sh
```

Дальше шару настраивают в админке Nextcloud → Внешние хранилища (SMB/CIFS).

Типичный вариант: логин пользователя из LDAP (`Log-in credentials, save in database`). Тогда `occ files_external:verify` из CLI пишет «No login credentials saved» — это ожидаемо, проверка идёт после входа пользователя.

## Обновление образа Nextcloud

Не делайте `docker pull nextcloud` + `up` голого `nextcloud:latest`. Собирайте свой образ:

```bash
./scripts/rebuild-image.sh
```

или

```bash
docker compose build nextcloud && docker compose up -d nextcloud
```

Иначе SMB снова исчезнет.

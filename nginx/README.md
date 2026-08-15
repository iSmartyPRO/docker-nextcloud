# Nginx

Образцы reverse proxy для Nextcloud и Collabora. TLS терминируется здесь, контейнеры слушают HTTP.

| Файл | Назначение |
|---|---|
| `cloud.conf.example` | HTTPS для `cloud.example.com` → `:8080` |
| `collabora.conf.example` | HTTPS для `collabora.example.com` → `:9980` |

Скопируйте `*.example` в `conf.d` своего nginx, замените домен и пути к сертификатам. Нужен `map` для `$connection_upgrade` — обычно он уже есть в общем конфиге.

Стендовые vhost’ы с боевыми именами в git не входят.

Подробности: [docs/nginx.md](../docs/nginx.md).

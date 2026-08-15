# Nginx

Образцы лежат в каталоге [`nginx/`](../nginx/).

## Схема

```
браузер
  → https://cloud.example.com      → 127.0.0.1:8080   (Nextcloud)
  → https://collabora.example.com  → 127.0.0.1:9980   (Collabora)
```

SSL терминируется на nginx. В Collabora включены `ssl.enable=false` и `ssl.termination=true`.

## Что скопировать

- `nginx/cloud.conf.example` → vhost облака
- `nginx/collabora.conf.example` → vhost редактора

Замените `example.com` и пути к сертификатам. Для больших загрузок у Nextcloud стоит `client_max_body_size 16G` и отключён buffering.

Нужны WebSocket-заголовки (`Upgrade` / `Connection`) — Collabora без них не откроет документ.

## CardDAV / CalDAV

В примере облака уже есть редиректы `/.well-known/carddav` и `/.well-known/caldav` на `/remote.php/dav`.

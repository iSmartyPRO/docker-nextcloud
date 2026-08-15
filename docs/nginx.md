# Nginx

Samples live in [`nginx/`](../nginx/).

## Layout

```
browser
  → https://cloud.example.com      → 127.0.0.1:8080   (Nextcloud)
  → https://collabora.example.com  → 127.0.0.1:9980   (Collabora)
```

TLS terminates on nginx. Collabora runs with `ssl.enable=false` and `ssl.termination=true`.

## What to copy

- `nginx/cloud.conf.example` → cloud vhost
- `nginx/collabora.conf.example` → editor vhost

Replace `example.com` and the certificate paths. For large uploads the Nextcloud vhost uses `client_max_body_size 16G` and buffering is off.

WebSocket headers (`Upgrade` / `Connection`) are required — Collabora will not open a document without them.

## CardDAV / CalDAV

The cloud sample already redirects `/.well-known/carddav` and `/.well-known/caldav` to `/remote.php/dav`.

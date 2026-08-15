# Nginx

Reverse-proxy samples for Nextcloud and Collabora. TLS terminates here; the containers listen on HTTP.

| File | Purpose |
|---|---|
| `cloud.conf.example` | HTTPS for `cloud.example.com` → `:8080` |
| `collabora.conf.example` | HTTPS for `collabora.example.com` → `:9980` |

Copy `*.example` into your nginx `conf.d`, then replace the domain and certificate paths. You need a `map` for `$connection_upgrade` — it is usually already in the main config.

Site-specific vhosts with production hostnames are not in git.

Details: [docs/nginx.md](../docs/nginx.md).

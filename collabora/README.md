# Collabora jail patch

Образ `collabora/code` в Docker не проходит self-test mount (UID 65534). Compose монтирует обёртки из этой папки:

| Файл | Роль |
|---|---|
| `coolmount` | Self-test завершается успешно, остальное идёт в `coolmount.real` |
| `coolmount.real` | Бинарник из образа Collabora |
| `busybox` | `/bin/sh` для jail (в образе нет shell) |
| `apply-caps.sh` | После смены образа CODE заново выставляет capabilities |

```bash
./collabora/apply-caps.sh
docker compose up -d collabora
```

Подробности: [docs/collabora.md](../docs/collabora.md).

# Collabora jail patch

The `collabora/code` image in Docker fails the mount self-test (UID 65534). Compose mounts wrappers from this directory:

| File | Role |
|---|---|
| `coolmount` | Self-test succeeds; everything else goes to `coolmount.real` |
| `coolmount.real` | Binary from the Collabora image |
| `busybox` | `/bin/sh` for the jail (the image has no shell) |
| `apply-caps.sh` | Re-applies capabilities after a CODE image change |

```bash
./collabora/apply-caps.sh
docker compose up -d collabora
```

Details: [docs/collabora.md](../docs/collabora.md).

# Collabora Online

Document editor (CODE) in the `${DOCKER_CONTAINER_NAME}_collabora` container. OnlyOffice is no longer in the stack.

## Start

1. Fill `COLLABORA_*` and `NEXTCLOUD_URL` in `.env`.
2. `COLLABORA_WOPI_HOST` is the cloud hostname without a scheme, for example `cloud.example.com`.
3. Start the service: `docker compose up -d collabora`.
4. Configure nginx (see [nginx.md](nginx.md)).
5. Bind it to Nextcloud:

```bash
./scripts/set-collabora.sh
```

Check:

```bash
curl -sk https://collabora.example.com/hosting/capabilities
docker exec -u 33 "$DOCKER_CONTAINER_NAME" php occ richdocuments:activate-config
```

## Jail patch

The CODE image in Docker fails the mount self-test. Files in `collabora/` are mounted into the container (see `collabora/README.md`).

After a Collabora image update:

```bash
./collabora/apply-caps.sh
docker compose up -d collabora
```

## Resources

The container limit is 2 GiB RAM, swap off. That is enough for 2–4 documents at once. If the limit is hit, only Collabora suffers, not the whole host.

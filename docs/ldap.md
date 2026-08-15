# LDAP / Active Directory

## Apply

Fill the `LDAP_*` block in `.env`, then:

```bash
./scripts/set-ldap.sh
```

Check without writing settings:

```bash
./scripts/test-ldap.sh
```

Default login filter:

```
(&(objectClass=person)(uid=%uid))
```

Change it with `occ ldap:set-config` or in the Nextcloud admin UI if needed.

## Useful commands

```bash
docker exec -u 33 "$DOCKER_CONTAINER_NAME" php occ ldap:show-config
docker exec -u 33 "$DOCKER_CONTAINER_NAME" php occ ldap:test-config s01
docker exec -u 33 "$DOCKER_CONTAINER_NAME" php occ user:report
```

The container must resolve the domain controller (`LDAP_HOST`) via `docker-lan` or the host DNS.

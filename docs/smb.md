# SMB / external storage

The SMB client is baked into `cloud-nextcloud:local` (`Dockerfile`): the `smbclient` package and the PHP `smbclient` extension. Recreating the container does not remove them.

## Enable the app

```bash
./scripts/apps-enable.sh
```

Then configure the share in Nextcloud admin → External storage (SMB/CIFS).

Typical setup: the LDAP user’s login (`Log-in credentials, save in database`). Then `occ files_external:verify` from the CLI prints “No login credentials saved” — that is expected. The check runs after the user signs in.

## Upgrade the Nextcloud image

Do not `docker pull nextcloud` and `up` a stock `nextcloud:latest`. Build your own image:

```bash
./scripts/rebuild-image.sh
```

or

```bash
docker compose build nextcloud && docker compose up -d nextcloud
```

Otherwise SMB disappears again.

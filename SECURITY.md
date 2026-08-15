# Security

## What must not be published

Do not commit:

- `.env` or any file that holds passwords
- the `files/` directory (webroot, `config.php`, user data)
- `backups/` and dumps (`*.sql`, `*.sql.gz`, `*.dump`)
- site-specific nginx vhosts with production hostnames
- certificates (`*.pem`, `*.key`, `*.crt`)

The only sample is [`.env.sample`](.env.sample). Do not use sample values in production.

## Report a vulnerability

Do not open a public issue that would let someone reach other people’s files, bypass LDAP, or spoof WOPI.

Contact the repository owner through a GitHub Security Advisory or a private message. Include:

- the affected component (`Nextcloud`, `files_cad`, `scripts`, `collabora`, nginx sample);
- image version / commit;
- steps with no production passwords and no user data;
- expected and actual result.

You will get a reply in a reasonable time. Details stay private until the issue is fixed.

## Operations

- Nextcloud listens only on `DOCKER_PORT` on the host. External nginx terminates TLS.
- Collabora is capped at 2 GiB RAM, Nextcloud at 1 GiB. Do not lift the limits on a 6 GiB host.
- `COLLABORA_WOPI_HOST` is the cloud hostname without a scheme. Do not allow a foreign host in WOPI.
- After `occ app:update --all`, run `occ files_cad:configure-fileviewer` again, or File Viewer may take over office files.

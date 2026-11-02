# Deployment

`simul-server` runs on one host in two environments, each a separate compose project with its own
container and data volume:

| Environment | Port | Deployed by |
|---|---|---|
| `staging` | 7778 | every push to `main` (`sha-<commit>`), and each release before production |
| `production` | 7777 | every `vX.Y.Z` tag (`X.Y.Z`), after it passed staging |

GitHub Actions connects over SSH, copies `compose.yml` and `deploy.sh` to `~/simul/<environment>/`
and runs `deploy.sh`, which pulls the image from ghcr.io, recreates the container and checks that it
runs. A failed start rolls back by itself; a failed smoke test makes the workflow roll back.

## One-time server setup

Rootless Podman with `podman-compose`, SSH on port 2222. As an admin, create the user that owns the
containers (no sudo) and let its containers run without a login session:

```sh
sudo useradd --create-home simul
sudo loginctl enable-linger simul
grep simul /etc/subuid /etc/subgid      # rootless Podman needs both ranges
```

Add the public keys to `/home/simul/.ssh/authorized_keys`: the CI deploy key prefixed with
`restrict ` (no forwarding, no terminal), and your own key:

```sh
sudo install -d -m 700 -o simul -g simul /home/simul/.ssh
sudo install -m 600 -o simul -g simul /dev/null /home/simul/.ssh/authorized_keys
sudoedit /home/simul/.ssh/authorized_keys
sudo restorecon -R /home/simul/.ssh
```

As `simul` (`ssh -p 2222 simul@<host>`):

```sh
systemctl --user enable --now podman-restart.service   # restarts the containers after a reboot
mkdir -p ~/simul/staging ~/simul/production
```

Create `~/simul/<environment>/.env` from [`.env.example`](.env.example): `COMPOSE_PROJECT_NAME`
(`simul-staging`, `simul-production`) and `SIMUL_PUBLIC_PORT` (7778, 7777).

## One-time GitHub setup

Repository variables: `DEPLOY_HOST`, `DEPLOY_PORT` (2222), `DEPLOY_USER` (`simul`), `SSH_KNOWN_HOSTS`
(`ssh-keyscan -p 2222 -t ed25519 <host>`, fingerprint checked against the server's
`/etc/ssh/ssh_host_ed25519_key.pub`), and `DEPLOY_ENABLED` (`true` turns deploys on).

Environments `staging` and `production`, both limited to the `main` branch and `v*.*.*` tags, each
with the secret `SSH_PRIVATE_KEY` (the CI deploy key) and the variable `SIMUL_PUBLIC_PORT`.

## Operations

- **Redeploy or roll back from GitHub:** Actions → Deploy → Run workflow, with an environment and
  an image tag.
- **Roll back on the server:** `bash ~/simul/<environment>/deploy.sh <environment> rollback` restores
  the state before the last deploy (once; the snapshot is used up).
- **Logs:** `podman logs simul-<environment>_server_1`.
- **Backup:** `deploy/backup.sh` on your own machine copies each environment's `.env` and data
  volume; the restore steps are in the script.
- Never run `podman-compose down -v`: it deletes the data volume.

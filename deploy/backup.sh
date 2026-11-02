#!/usr/bin/env bash
# Copies the server's data to this machine, into <backup-dir>/<date>_<time>/:
#
#   deploy/backup.sh [backup-dir]        (default: ~/simul-backups)
#
# For each environment: its .env and a tar export of its data volume. Restore on the server, in
# ~/simul/<environment>/:
#
#   podman-compose down                  (never with -v)
#   podman volume rm simul-<environment>_data
#   podman volume create --opt o=uid=10001,gid=10001 simul-<environment>_data
#   podman volume import simul-<environment>_data <environment>-data.tar
#   podman-compose up -d
#
# The export doesn't keep the owner of the volume's top directory; without the uid/gid options it
# would be root and the server (uid 10001 in the image) couldn't create files in it.
set -euo pipefail

ssh_target=${SIMUL_SSH_TARGET:-simul@simul.fri.uniza.sk}
ssh_port=${SIMUL_SSH_PORT:-2222}
dest=${1:-$HOME/simul-backups}/$(date +%Y-%m-%d_%H%M%S)

remote() {
    ssh -p "$ssh_port" "$ssh_target" "$@"
}

mkdir -p "$dest"
for environment in staging production; do
    if remote "test -f simul/$environment/.env"; then
        remote "cat simul/$environment/.env" > "$dest/$environment.env"
    fi
    # TODO: once SQLite exists, export a consistent copy (.backup) instead of the live file.
    volume=simul-${environment}_data
    if remote "podman volume exists $volume"; then
        remote "podman volume export $volume" > "$dest/$environment-data.tar"
    else
        echo "$volume does not exist, skipped"
    fi
done

echo "Backup in $dest:"
ls -l "$dest"

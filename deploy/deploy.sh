#!/usr/bin/env bash
# Deploys an image tag to one environment, or rolls back the previous deploy.
#
#   deploy.sh <staging|production> <tag>
#   deploy.sh <staging|production> rollback
#
# Runs on the server as the user that owns the containers; CI pipes it over SSH. Works in
# ~/simul/<environment>/, which needs a .env (see .env.example). A new compose file can be placed
# there as compose.yml.next and is taken over by the deploy. Before changing anything, the current
# compose.yml and .env are copied to previous/, which is what a rollback restores. If the new
# container doesn't start, the deploy rolls back by itself.
set -euo pipefail

readonly image_source=https://github.com/filipbaranek/Simul

usage() {
    echo "usage: $0 <staging|production> <tag|rollback>" >&2
    exit 2
}

die() {
    echo "error: $*" >&2
    exit 1
}

# env_value <name> [file]
env_value() {
    sed -n "s/^$1=//p" "${2:-.env}" | tail -n1
}

set_env_value() {
    if grep -q "^$1=" .env; then
        sed -i "s|^$1=.*|$1=$2|" .env
    else
        echo "$1=$2" >> .env
    fi
}

restore_previous() {
    [[ -d previous ]] || die "nothing to roll back to"
    podman pull --quiet "$repository:$(env_value SIMUL_IMAGE_TAG previous/.env)" > /dev/null
    cp previous/compose.yml previous/.env .
    rm -r previous
    rm -f compose.yml.next
}

# Recreates the container and checks that it runs the configured image. Called in a condition, where
# `set -e` doesn't apply, so every failure returns explicitly.
start() {
    local image container running restarts container_image expected_image
    image=$repository:$(env_value SIMUL_IMAGE_TAG)

    podman-compose up -d --force-recreate || return 1

    # Give a server that crashes on startup the time to do so.
    sleep 5

    container=$(podman ps -a --format '{{.ID}}' \
        --filter "label=io.podman.compose.project=simul-$environment" \
        --filter "label=com.docker.compose.service=server") || return 1
    if [[ $(wc -w <<< "$container") -ne 1 ]]; then
        echo "error: expected one server container, found: ${container:-none}" >&2
        return 1
    fi

    read -r running restarts container_image < <(
        podman inspect --format '{{.State.Running}} {{.RestartCount}} {{.Image}}' "$container") || return 1
    expected_image=$(podman image inspect --format '{{.Id}}' "$image") || return 1
    if [[ $running != true || $restarts != 0 || $container_image != "$expected_image" ]]; then
        echo "error: the server container is not running $image (running=$running, restarts=$restarts). Its log:" >&2
        podman logs --tail 50 "$container" >&2 || true
        return 1
    fi

    echo "$environment runs $image (commit" \
        "$(podman image inspect --format '{{index .Labels "org.opencontainers.image.revision"}}' "$image"))"
}

[[ $# -eq 2 ]] || usage
environment=$1
target=$2
[[ $environment =~ ^(staging|production)$ ]] || usage
# Docker's tag grammar.
[[ $target =~ ^[A-Za-z0-9_][A-Za-z0-9_.-]{0,127}$ ]] || die "invalid tag '$target'"

dir=${SIMUL_DEPLOY_ROOT:-$HOME/simul}/$environment
cd "$dir" 2>/dev/null || die "$dir does not exist"
[[ -f .env ]] || die "$dir/.env is missing (see .env.example)"
[[ $(env_value COMPOSE_PROJECT_NAME) == "simul-$environment" ]] \
    || die "COMPOSE_PROJECT_NAME in $dir/.env is not 'simul-$environment'"

current=$(env_value SIMUL_IMAGE_TAG)
repository=$(env_value SIMUL_IMAGE)
repository=${repository:-ghcr.io/filipbaranek/simul-server}

if [[ $target == rollback ]]; then
    restore_previous
    echo "Rolling back $environment from ${current:-nothing} to $(env_value SIMUL_IMAGE_TAG)"
    start || die "rollback failed"
else
    # Pulled before anything is changed, so a wrong tag leaves the environment as it was.
    podman pull --quiet "$repository:$target" > /dev/null

    # A re-run of the same deploy must not overwrite the snapshot of the real previous state.
    unchanged=false
    if [[ $current == "$target" ]] && { [[ ! -f compose.yml.next ]] || cmp -s compose.yml.next compose.yml; }; then
        unchanged=true
    fi
    if [[ -n $current && -f compose.yml && $unchanged == false ]]; then
        mkdir -p previous
        cp compose.yml .env previous/
    fi

    if [[ -f compose.yml.next ]]; then
        mv compose.yml.next compose.yml
    fi
    [[ -f compose.yml ]] || die "$dir/compose.yml is missing"
    set_env_value SIMUL_IMAGE_TAG "$target"
    echo "Deploying $target to $environment (was ${current:-nothing})"

    if ! start; then
        if [[ -d previous ]]; then
            echo "Deploy failed, rolling back to $(env_value SIMUL_IMAGE_TAG previous/.env)" >&2
            restore_previous
            start || echo "error: the rollback failed too" >&2
        fi
        exit 1
    fi
fi

# Keeps the images the containers use (both environments); older ones can be pulled again.
podman image prune --all --force --filter "label=org.opencontainers.image.source=$image_source" > /dev/null

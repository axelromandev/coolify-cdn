#!/bin/bash
## Do not modify this file. You will lose the ability to autoupdate!

VERSION="13"
CDN="https://raw.githubusercontent.com/axelromandev/coolify-cdn/refs/heads/main"
LATEST_IMAGE=${1:-latest}
LATEST_HELPER_VERSION=${2:-latest}

DATE=$(date +%Y-%m-%d-%H-%M-%S)
LOGFILE="/mnt/HeavyStorage/coolify/source/upgrade-${DATE}.log"

curl -fsSL $CDN/docker-compose.yml -o /mnt/HeavyStorage/coolify/source/docker-compose.yml
curl -fsSL $CDN/docker-compose.prod.yml -o /mnt/HeavyStorage/coolify/source/docker-compose.prod.yml
curl -fsSL $CDN/.env.production -o /mnt/HeavyStorage/coolify/source/.env.production

# Merge .env and .env.production. New values will be added to .env
awk -F '=' '!seen[$1]++' /mnt/HeavyStorage/coolify/source/.env /mnt/HeavyStorage/coolify/source/.env.production  > /mnt/HeavyStorage/coolify/source/.env.tmp && mv /mnt/HeavyStorage/coolify/source/.env.tmp /mnt/HeavyStorage/coolify/source/.env
# Check if PUSHER_APP_ID or PUSHER_APP_KEY or PUSHER_APP_SECRET is empty in /mnt/HeavyStorage/coolify/source/.env
if grep -q "PUSHER_APP_ID=$" /mnt/HeavyStorage/coolify/source/.env; then
    sed -i "s|PUSHER_APP_ID=.*|PUSHER_APP_ID=$(openssl rand -hex 32)|g" /mnt/HeavyStorage/coolify/source/.env
fi

if grep -q "PUSHER_APP_KEY=$" /mnt/HeavyStorage/coolify/source/.env; then
    sed -i "s|PUSHER_APP_KEY=.*|PUSHER_APP_KEY=$(openssl rand -hex 32)|g" /mnt/HeavyStorage/coolify/source/.env
fi

if grep -q "PUSHER_APP_SECRET=$" /mnt/HeavyStorage/coolify/source/.env; then
    sed -i "s|PUSHER_APP_SECRET=.*|PUSHER_APP_SECRET=$(openssl rand -hex 32)|g" /mnt/HeavyStorage/coolify/source/.env
fi

# Make sure coolify network exists
# It is created when starting Coolify with docker compose
docker network create --attachable coolify 2>/dev/null
# docker network create --attachable --driver=overlay coolify-overlay 2>/dev/null

echo "If you encounter any issues, please check the log file: $LOGFILE"
if [ -f /mnt/HeavyStorage/coolify/source/docker-compose.custom.yml ]; then
    echo "docker-compose.custom.yml detected." >> $LOGFILE
    docker run -v /mnt/HeavyStorage/coolify/source:/mnt/HeavyStorage/coolify/source -v /var/run/docker.sock:/var/run/docker.sock --rm ghcr.io/coollabsio/coolify-helper:${LATEST_HELPER_VERSION} bash -c "LATEST_IMAGE=${LATEST_IMAGE} docker compose --env-file /mnt/HeavyStorage/coolify/source/.env -f /mnt/HeavyStorage/coolify/source/docker-compose.yml -f /mnt/HeavyStorage/coolify/source/docker-compose.prod.yml -f /mnt/HeavyStorage/coolify/source/docker-compose.custom.yml up -d --remove-orphans --force-recreate --wait --wait-timeout 60" >> $LOGFILE 2>&1
else
    docker run -v /mnt/HeavyStorage/coolify/source:/mnt/HeavyStorage/coolify/source -v /var/run/docker.sock:/var/run/docker.sock --rm ghcr.io/coollabsio/coolify-helper:${LATEST_HELPER_VERSION} bash -c "LATEST_IMAGE=${LATEST_IMAGE} docker compose --env-file /mnt/HeavyStorage/coolify/source/.env -f /mnt/HeavyStorage/coolify/source/docker-compose.yml -f /mnt/HeavyStorage/coolify/source/docker-compose.prod.yml up -d --remove-orphans --force-recreate --wait --wait-timeout 60" >> $LOGFILE 2>&1
fi

#!/bin/bash
set -e

# -----------------------------
# OS + Docker setup (Ubuntu)
# -----------------------------
apt-get update -y
apt-get install -y docker.io curl

systemctl enable docker
systemctl start docker

# -----------------------------
# Docker Compose plugin
# -----------------------------
mkdir -p /usr/local/lib/docker/cli-plugins
curl -SL https://github.com/docker/compose/releases/latest/download/docker-compose-linux-x86_64 \
  -o /usr/local/lib/docker/cli-plugins/docker-compose
chmod +x /usr/local/lib/docker/cli-plugins/docker-compose

# -----------------------------
# CLEAN old data (CRITICAL)
# -----------------------------
docker rm -f postgres17 || true
rm -rf /postgres17
mkdir -p /postgres17/data
chown -R 999:999 /postgres17

# -----------------------------
# Docker Compose (TZ SAFE IMAGE)
# -----------------------------
cat <<EOF > /postgres17/docker-compose.yml
version: "3.8"
services:
  postgres:
    image: timescale/timescaledb:latest-pg17
    container_name: postgres17
    restart: always
    ports:
      - "0.0.0.0:5432:5432"
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
      POSTGRES_DB: appdb
    volumes:
      - /postgres17/data:/var/lib/postgresql/data
EOF

# -----------------------------
# Start PostgreSQL
# -----------------------------
cd /postgres17
docker compose up -d

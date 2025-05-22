#!/usr/bin/env bash
set -euo pipefail

echo "開始清理 Docker 資源..."

docker container prune --force
docker image prune --all --force
docker volume prune --force
docker network prune --force
docker builder prune --all --force
docker system prune --all --volumes --force

echo "Docker 資源清理完成。"
#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cd "$ROOT_DIR"
git pull --ff-only
docker compose -f docker-compose.yml -f docker-compose.prod.yml up --build -d
docker image prune -f


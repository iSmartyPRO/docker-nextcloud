#!/usr/bin/env bash
# Load project root and .env. Source from any script in scripts/.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

if [[ ! -f .env ]]; then
  echo "Файл .env не найден в ${ROOT}. Скопируйте .env.sample → .env" >&2
  exit 1
fi

set -a
# shellcheck disable=SC1091
source .env
set +a

if [[ -z "${DOCKER_CONTAINER_NAME:-}" ]]; then
  echo "В .env не задан DOCKER_CONTAINER_NAME" >&2
  exit 1
fi

#!/usr/bin/env bash
# update.sh – Update the OpenClaw gateway image only, preserving all data.
# Does NOT touch the open-webui container or Ollama volumes.
# Runs post-upgrade-check.sh at the end and sends a Telegram summary.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${SCRIPT_DIR}"

echo "[update-openclaw] Pulling latest ghcr.io/openclaw/openclaw image …"
docker pull ghcr.io/openclaw/openclaw:latest

NEW_DIGEST=$(docker inspect ghcr.io/openclaw/openclaw:latest --format '{{index .RepoDigests 0}}' 2>/dev/null)
echo "[update-openclaw] New digest: ${NEW_DIGEST}"

echo "[update-openclaw] Recreating openclaw-gateway container …"
docker compose up -d --no-deps --force-recreate openclaw-gateway

echo "[update-openclaw] Waiting for gateway to become healthy …"
for i in $(seq 1 30); do
  STATUS=$(docker inspect --format='{{.State.Health.Status}}' openclaw-gateway 2>/dev/null || echo "unknown")
  echo "  Status: ${STATUS}"
  if [ "${STATUS}" = "healthy" ]; then
    break
  fi
  sleep 3
done

echo "[update-openclaw] Re-enabling plugins that require explicit activation …"
docker exec openclaw-gateway node openclaw.mjs plugins enable brave
docker compose restart openclaw-gateway
echo "[update-openclaw] Waiting for gateway to become healthy after plugin restart …"
for i in $(seq 1 30); do
  STATUS=$(docker inspect --format='{{.State.Health.Status}}' openclaw-gateway 2>/dev/null || echo "unknown")
  echo "  Status: ${STATUS}"
  if [ "${STATUS}" = "healthy" ]; then
    break
  fi
  sleep 3
done

echo ""
echo "[update-openclaw] Running post-upgrade health checks …"
"${SCRIPT_DIR}/post-upgrade-check.sh" --notify

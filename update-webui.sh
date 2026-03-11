#!/usr/bin/env bash
# update-webui.sh – Update Open WebUI + Ollama image while preserving all data
#
# Preserves:
#   - open-webui Docker volume     (WebUI database, settings)
#   - open-webui-ollama volume     (all downloaded models)
#   - ai-stack network membership
#   - Port bindings (12000, 11435)
#   - OLLAMA_HOST=0.0.0.0:11434 environment variable
#
# Does NOT touch the openclaw-gateway container.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${SCRIPT_DIR}"

echo "[update-webui] Pulling latest ghcr.io/open-webui/open-webui:ollama …"
docker pull ghcr.io/open-webui/open-webui:ollama

NEW_DIGEST=$(docker inspect ghcr.io/open-webui/open-webui:ollama --format '{{index .RepoDigests 0}}' 2>/dev/null)
echo "[update-webui] New digest: ${NEW_DIGEST}"

echo "[update-webui] Recreating open-webui container (volumes preserved) …"
# --no-deps: only restart open-webui, not openclaw-gateway
docker compose up -d --no-deps open-webui

echo "[update-webui] Waiting for Open WebUI to become healthy …"
for i in $(seq 1 60); do
  STATUS=$(docker inspect --format='{{.State.Health.Status}}' open-webui 2>/dev/null || echo "unknown")
  echo "  Status: ${STATUS}"
  if [ "${STATUS}" = "healthy" ]; then
    break
  fi
  sleep 5
done

# Verify Ollama API still accessible
if docker exec open-webui curl -sf http://localhost:11434/api/tags &>/dev/null; then
  MODEL_COUNT=$(docker exec open-webui ollama list 2>/dev/null | tail -n +2 | wc -l)
  echo "[update-webui] Ollama OK. Models intact: ${MODEL_COUNT}"
else
  echo "[update-webui] WARNING: Ollama not yet responding inside container. Check logs."
fi

echo "[update-webui] Done."
echo "  Open WebUI: http://localhost:12000"
echo ""
echo "If Ollama models appear to be missing, they are still in the volume."
echo "Verify: docker exec open-webui ollama list"
echo ""
echo "To rollback to the previous image:"
echo "  docker compose down --rmi local"
echo "  docker pull ghcr.io/open-webui/open-webui:ollama@<old-digest>"
echo "  # Edit docker-compose.yml to pin to that digest, then: docker compose up -d"

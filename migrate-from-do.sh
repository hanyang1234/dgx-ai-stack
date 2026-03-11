#!/usr/bin/env bash
# migrate-from-do.sh – Migrate OpenClaw config from a DigitalOcean instance
# Usage: ./migrate-from-do.sh user@do-ip-or-hostname [remote-openclaw-path]
#
# What it does:
#   1. Backs up existing local ~/openclaw-config
#   2. rsyncs ~/.openclaw from the remote DO instance
#   3. Re-injects the local Ollama provider block (DO won't have it)
#   4. Re-injects the local gateway token from .env
#   5. Restarts the openclaw-gateway Docker container
set -euo pipefail

REMOTE="${1:-}"
REMOTE_PATH="${2:-~/.openclaw}"
LOCAL_CONFIG="${HOME}/openclaw-config"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -z "${REMOTE}" ]; then
  echo "Usage: $0 user@do-ip [remote-openclaw-path]"
  echo "  Example: $0 root@192.0.2.10"
  echo "  Example: $0 ubuntu@192.0.2.10 ~/.openclaw"
  exit 1
fi

# ── 1. Prerequisites ─────────────────────────────────────────────────────────
for cmd in rsync jq docker; do
  if ! command -v "${cmd}" &>/dev/null; then
    echo "[migrate] ERROR: '${cmd}' is required but not installed."
    exit 1
  fi
done

# Load .env if present
if [ -f "${SCRIPT_DIR}/.env" ]; then
  set -a; source "${SCRIPT_DIR}/.env"; set +a
fi

# ── 2. Backup existing local config ──────────────────────────────────────────
BACKUP_DIR="${LOCAL_CONFIG}.bak.$(date +%Y%m%d-%H%M%S)"
if [ -d "${LOCAL_CONFIG}" ]; then
  echo "[migrate] Backing up existing config to: ${BACKUP_DIR}"
  cp -a "${LOCAL_CONFIG}" "${BACKUP_DIR}"
fi

# ── 3. rsync from DO ─────────────────────────────────────────────────────────
echo "[migrate] Syncing from ${REMOTE}:${REMOTE_PATH} …"
echo "          (SSH key auth recommended – you may be prompted for a password)"

mkdir -p "${LOCAL_CONFIG}"

rsync -avz --progress \
  --exclude='logs/' \
  --exclude='*.log' \
  --exclude='update-check.json' \
  "${REMOTE}:${REMOTE_PATH}/" \
  "${LOCAL_CONFIG}/"

echo "[migrate] Sync complete."

# ── 4. Re-inject Ollama provider block ───────────────────────────────────────
echo "[migrate] Re-wiring Ollama provider to http://open-webui:11434 …"

OPENCLAW_JSON="${LOCAL_CONFIG}/openclaw.json"

if [ ! -f "${OPENCLAW_JSON}" ]; then
  echo "[migrate] ERROR: openclaw.json not found after sync. Aborting."
  exit 1
fi

# Add/update Ollama provider block with this machine's internal hostname
jq '
  .models.providers.ollama = {
    "baseUrl": "http://open-webui:11434",
    "apiKey": "ollama-local",
    "api": "ollama",
    "models": [
      {
        "id": "gpt-oss:120b",
        "name": "GPT-OSS 120B (Local — large reasoning)",
        "reasoning": false,
        "input": ["text"],
        "cost": { "input": 0, "output": 0, "cacheRead": 0, "cacheWrite": 0 },
        "contextWindow": 65536,
        "maxTokens": 655360
      },
      {
        "id": "gpt-oss:20b",
        "name": "GPT-OSS 20B Fast (Local — subagents)",
        "reasoning": false,
        "input": ["text"],
        "cost": { "input": 0, "output": 0, "cacheRead": 0, "cacheWrite": 0 },
        "contextWindow": 65536,
        "maxTokens": 655360
      },
      {
        "id": "qwen3-coder:latest",
        "name": "Qwen3-Coder (Local — coding)",
        "reasoning": false,
        "input": ["text"],
        "cost": { "input": 0, "output": 0, "cacheRead": 0, "cacheWrite": 0 },
        "contextWindow": 65536,
        "maxTokens": 655360
      },
      {
        "id": "nemotron-3-nano:latest",
        "name": "Nemotron-3 Nano (Local — fast/light)",
        "reasoning": false,
        "input": ["text"],
        "cost": { "input": 0, "output": 0, "cacheRead": 0, "cacheWrite": 0 },
        "contextWindow": 65536,
        "maxTokens": 655360
      }
    ]
  }
' "${OPENCLAW_JSON}" > /tmp/openclaw-migrated.json
mv /tmp/openclaw-migrated.json "${OPENCLAW_JSON}"

# ── 5. Re-inject local gateway token ────────────────────────────────────────
if [ -n "${OPENCLAW_GATEWAY_TOKEN:-}" ]; then
  echo "[migrate] Re-injecting local gateway token …"
  jq --arg token "${OPENCLAW_GATEWAY_TOKEN}" \
    '.gateway.auth.token = $token' \
    "${OPENCLAW_JSON}" > /tmp/openclaw-migrated.json
  mv /tmp/openclaw-migrated.json "${OPENCLAW_JSON}"
else
  echo "[migrate] WARNING: OPENCLAW_GATEWAY_TOKEN not set in .env – keeping DO token."
  echo "          Paired clients will need to re-authenticate after restart."
fi

# ── 6. Update workspace path to Docker container path ────────────────────────
echo "[migrate] Updating workspace path to /home/node/workspace …"
jq '.agents.defaults.workspace = "/home/node/workspace"' \
  "${OPENCLAW_JSON}" > /tmp/openclaw-migrated.json
mv /tmp/openclaw-migrated.json "${OPENCLAW_JSON}"

# Disable iMessage channel (not available in Docker)
jq '
  if .channels.imessage then
    .channels.imessage.enabled = false
  else
    .
  end |
  if .plugins.entries.imessage then
    .plugins.entries.imessage.enabled = false
  else
    .
  end
' "${OPENCLAW_JSON}" > /tmp/openclaw-migrated.json
mv /tmp/openclaw-migrated.json "${OPENCLAW_JSON}"

# ── 7. Restart the gateway container ────────────────────────────────────────
echo "[migrate] Restarting openclaw-gateway container …"
cd "${SCRIPT_DIR}"
docker compose restart openclaw-gateway

echo ""
echo "[migrate] Migration complete!"
echo ""
echo "What was migrated:"
echo "  - Agents, sessions, memory, skills from DO instance"
echo "  - openclaw.json (with Ollama block re-injected and workspace path updated)"
echo ""
echo "What was NOT changed:"
echo "  - Ollama models (stay on this machine)"
echo "  - open-webui volume (your local WebUI data)"
echo ""
echo "Verify with:"
echo "  docker compose logs -f openclaw-gateway"
echo "  openclaw models list  # (from host CLI, points at local gateway)"
echo ""
echo "Local backup saved to: ${BACKUP_DIR}"

#!/usr/bin/env bash
# restore.sh – Clone repo, inject .env, and bring up the AI stack on a fresh machine
# Usage: ./restore.sh <repo-url> [target-dir]
# Prereqs: docker, docker compose v2, git, jq
set -euo pipefail

REPO_URL="${1:-}"
TARGET_DIR="${2:-${HOME}/ai-stack}"

if [ -z "${REPO_URL}" ]; then
  echo "Usage: $0 <github-repo-url> [target-dir]"
  echo "  Example: $0 git@github.com:you/ai-stack.git"
  exit 1
fi

echo "[restore] Target directory: ${TARGET_DIR}"

# ── 1. Prerequisites ─────────────────────────────────────────────────────────
for cmd in docker git jq; do
  if ! command -v "${cmd}" &>/dev/null; then
    echo "[restore] ERROR: '${cmd}' is required but not installed."
    exit 1
  fi
done
docker compose version &>/dev/null || { echo "[restore] ERROR: docker compose v2 required."; exit 1; }

# ── 2. Clone ─────────────────────────────────────────────────────────────────
if [ -d "${TARGET_DIR}" ]; then
  echo "[restore] Directory exists – pulling latest changes instead of cloning"
  git -C "${TARGET_DIR}" pull
else
  git clone "${REPO_URL}" "${TARGET_DIR}"
fi
cd "${TARGET_DIR}"

# ── 3. .env setup ────────────────────────────────────────────────────────────
if [ ! -f .env ]; then
  echo ""
  echo "[restore] No .env file found. You must create one before continuing."
  echo "          Copy .env.example and fill in your credentials:"
  echo ""
  echo "          cp .env.example .env && \$EDITOR .env"
  echo ""
  read -rp "Press ENTER once .env is ready, or Ctrl-C to abort: "
fi

if [ ! -f .env ]; then
  echo "[restore] ERROR: .env still missing. Aborting."
  exit 1
fi

# Source .env to load variables for the re-injection steps below
set -a; source .env; set +a

# ── 4. Create Docker network ─────────────────────────────────────────────────
if ! docker network inspect ai-stack &>/dev/null; then
  echo "[restore] Creating ai-stack network …"
  docker network create --driver bridge ai-stack
else
  echo "[restore] ai-stack network already exists."
fi

# ── 5. Create Docker volumes ──────────────────────────────────────────────────
for vol in open-webui open-webui-ollama; do
  if ! docker volume inspect "${vol}" &>/dev/null; then
    echo "[restore] Creating Docker volume: ${vol}"
    docker volume create "${vol}"
  else
    echo "[restore] Volume already exists: ${vol}"
  fi
done

# ── 6. Restore OpenClaw config ───────────────────────────────────────────────
OPENCLAW_CONFIG="${HOME}/openclaw-config"
OPENCLAW_WORKSPACE="${HOME}/openclaw/workspace"

mkdir -p "${OPENCLAW_CONFIG}" "${OPENCLAW_WORKSPACE}"

if [ -f sanitized/openclaw.sanitized.json ]; then
  echo "[restore] Restoring OpenClaw config from sanitized backup …"

  # Start from the sanitized config
  cp sanitized/openclaw.sanitized.json "${OPENCLAW_CONFIG}/openclaw.json"

  # Re-inject gateway token from .env
  if [ -n "${OPENCLAW_GATEWAY_TOKEN:-}" ]; then
    echo "[restore] Re-injecting gateway token …"
    jq --arg token "${OPENCLAW_GATEWAY_TOKEN}" \
      '.gateway.auth.token = $token' \
      "${OPENCLAW_CONFIG}/openclaw.json" > /tmp/openclaw-restore.json
    mv /tmp/openclaw-restore.json "${OPENCLAW_CONFIG}/openclaw.json"
  fi

  # Re-wire Ollama provider to this machine's hostname
  echo "[restore] Re-wiring Ollama provider to http://open-webui:11434 …"
  jq '.models.providers.ollama.baseUrl = "http://open-webui:11434"' \
    "${OPENCLAW_CONFIG}/openclaw.json" > /tmp/openclaw-restore.json
  mv /tmp/openclaw-restore.json "${OPENCLAW_CONFIG}/openclaw.json"

  # Write provider API keys to openclaw .env file (OpenClaw reads this on start)
  OPENCLAW_ENV="${OPENCLAW_CONFIG}/.env"
  touch "${OPENCLAW_ENV}"
  chmod 600 "${OPENCLAW_ENV}"

  # Preserve existing keys, update/add from our .env
  if [ -n "${ANTHROPIC_API_KEY:-}" ]; then
    if grep -q "ANTHROPIC_API_KEY" "${OPENCLAW_ENV}" 2>/dev/null; then
      sed -i "s|^ANTHROPIC_API_KEY=.*|ANTHROPIC_API_KEY=${ANTHROPIC_API_KEY}|" "${OPENCLAW_ENV}"
    else
      echo "ANTHROPIC_API_KEY=${ANTHROPIC_API_KEY}" >> "${OPENCLAW_ENV}"
    fi
  fi

  echo "[restore] OpenClaw config restored."
else
  echo "[restore] No sanitized config found – creating minimal config."
  mkdir -p "${OPENCLAW_CONFIG}"
fi

# ── 7. Bring up the stack ────────────────────────────────────────────────────
echo "[restore] Starting Docker Compose stack …"
docker compose up -d

echo ""
echo "[restore] Waiting for health checks …"
for i in $(seq 1 30); do
  WEBUI_STATUS=$(docker inspect --format='{{.State.Health.Status}}' open-webui 2>/dev/null || echo "missing")
  GATEWAY_STATUS=$(docker inspect --format='{{.State.Health.Status}}' openclaw-gateway 2>/dev/null || echo "missing")
  echo "  open-webui: ${WEBUI_STATUS}   openclaw-gateway: ${GATEWAY_STATUS}"
  if [ "${WEBUI_STATUS}" = "healthy" ] && [ "${GATEWAY_STATUS}" = "healthy" ]; then
    break
  fi
  sleep 5
done

echo ""
echo "[restore] Stack is up!"
echo "  Open WebUI : http://localhost:12000"
echo "  OpenClaw   : http://127.0.0.1:18789"
echo ""
echo "Manual steps remaining:"
echo "  1. Set your ANTHROPIC_API_KEY in .env if not already done"
echo "  2. Pair your client device: openclaw devices list"
echo "  3. Verify Ollama models: docker exec open-webui ollama list"

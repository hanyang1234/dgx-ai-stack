#!/usr/bin/env bash
# backup.sh – Sanitize OpenClaw config and commit safe files to GitHub
# Usage: ./backup.sh [remote-name]
# Default remote: origin
set -euo pipefail

REMOTE="${1:-origin}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OPENCLAW_CONFIG_DIR="${HOME}/openclaw-config"
SANITIZED_DIR="${SCRIPT_DIR}/sanitized"

echo "[backup] Starting backup to remote: ${REMOTE}"

# ── 1. Sanity checks ────────────────────────────────────────────────────────
if ! command -v jq &>/dev/null; then
  echo "[backup] ERROR: jq is required but not installed. Run: sudo apt install jq"
  exit 1
fi
if ! git -C "${SCRIPT_DIR}" rev-parse --git-dir &>/dev/null; then
  echo "[backup] ERROR: ${SCRIPT_DIR} is not a git repository."
  echo "         Run: git init && git remote add origin <url>"
  exit 1
fi

# ── 2. Build sanitized config ────────────────────────────────────────────────
echo "[backup] Sanitizing openclaw.json …"
mkdir -p "${SANITIZED_DIR}"

# Strip credential-bearing fields but PRESERVE the Ollama provider block
# Removed fields:
#   gateway.auth.token     – bearer token for gateway API
#   env.*                  – any inline API keys in the config
#   models.providers.*.apiKey (non-ollama providers)
# Preserved:
#   models.providers.ollama  – no credentials, just baseUrl and model list
jq '
  del(.gateway.auth.token) |
  del(.env) |
  (
    if .models.providers then
      .models.providers |= with_entries(
        if .key != "ollama" then
          .value |= del(.apiKey, .token, .secret, .key)
        else
          .
        end
      )
    else
      .
    end
  )
' "${OPENCLAW_CONFIG_DIR}/openclaw.json" > "${SANITIZED_DIR}/openclaw.sanitized.json"

echo "[backup] Sanitized config written to: ${SANITIZED_DIR}/openclaw.sanitized.json"

# Verify no secrets leaked
for secret_field in "auth.token" "apiKey" "ANTHROPIC_API_KEY" "OPENAI_API_KEY"; do
  if grep -q "sk-ant\|sk-proj\|sk-or\|d48bd6a2" "${SANITIZED_DIR}/openclaw.sanitized.json" 2>/dev/null; then
    echo "[backup] WARNING: Possible credential in sanitized output. Aborting."
    echo "         Run: jq . ${SANITIZED_DIR}/openclaw.sanitized.json"
    exit 1
  fi
done

# ── 3. Copy safe files from openclaw-config ──────────────────────────────────
echo "[backup] Copying personality and memory files …"
PERSONALITY_DIR="${SCRIPT_DIR}/openclaw-personality"
mkdir -p "${PERSONALITY_DIR}"

# Workspace personality/identity markdown files (the "soul" of the agent)
# These are safe – no credentials, just agent behaviour definitions
for mdfile in SOUL.md IDENTITY.md AGENTS.md BOOTSTRAP.md USER.md TOOLS.md HEARTBEAT.md; do
  src="${OPENCLAW_CONFIG_DIR}/workspace/${mdfile}"
  if [ -f "${src}" ]; then
    cp "${src}" "${PERSONALITY_DIR}/${mdfile}"
    echo "[backup]   + ${mdfile}"
  fi
done

# Any additional markdown files in workspace root (custom memory, etc.)
find "${OPENCLAW_CONFIG_DIR}/workspace" -maxdepth 1 -name "*.md" \
  ! -name "SOUL.md" ! -name "IDENTITY.md" ! -name "AGENTS.md" \
  ! -name "BOOTSTRAP.md" ! -name "USER.md" ! -name "TOOLS.md" \
  ! -name "HEARTBEAT.md" 2>/dev/null | while read -r f; do
    cp "${f}" "${PERSONALITY_DIR}/$(basename "${f}")"
    echo "[backup]   + $(basename "${f}") (extra)"
done

# AGENT_INFRA.md – Artoo's agent infrastructure knowledge base
# Lives in the Docker workspace bind-mount (~/openclaw/workspace/), not openclaw-config
AGENT_INFRA_SRC="${HOME}/openclaw/workspace/AGENT_INFRA.md"
if [ -f "${AGENT_INFRA_SRC}" ]; then
  cp "${AGENT_INFRA_SRC}" "${PERSONALITY_DIR}/AGENT_INFRA.md"
  echo "[backup]   + AGENT_INFRA.md (from ~/openclaw/workspace)"
fi

# Skills and hooks from agents/main (markdown + shell only, no session data)
if [ -d "${OPENCLAW_CONFIG_DIR}/agents/main" ]; then
  find "${OPENCLAW_CONFIG_DIR}/agents/main" \
    \( -name "*.md" -o -name "*.sh" \) \
    ! -path "*/sessions/*" 2>/dev/null | while read -r f; do
      rel="${f#${OPENCLAW_CONFIG_DIR}/agents/main/}"
      dest="${PERSONALITY_DIR}/agents-main/${rel}"
      mkdir -p "$(dirname "${dest}")"
      cp "${f}" "${dest}"
      echo "[backup]   + agents/main/${rel}"
  done
fi

# Cron jobs (schedule definitions, no credentials)
if [ -f "${OPENCLAW_CONFIG_DIR}/cron/jobs.json" ]; then
  cp "${OPENCLAW_CONFIG_DIR}/cron/jobs.json" "${PERSONALITY_DIR}/cron-jobs.json"
  echo "[backup]   + cron-jobs.json"
fi

# ── 4. Git staging ───────────────────────────────────────────────────────────
echo "[backup] Staging safe files …"
cd "${SCRIPT_DIR}"

git add docker-compose.yml
git add .env.example
git add .gitignore
git add backup.sh restore.sh update.sh update-webui.sh migrate-from-do.sh 2>/dev/null || true
git add DEPLOYMENT.md HANDOFF.md 2>/dev/null || true
git add sanitized/ 2>/dev/null || true
git add openclaw-personality/ 2>/dev/null || true

# ── 5. Commit ────────────────────────────────────────────────────────────────
TIMESTAMP="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
COMMIT_MSG="backup: stack config ${TIMESTAMP}"

if git diff --cached --quiet; then
  echo "[backup] Nothing new to commit – repository is up to date."
else
  git commit -m "${COMMIT_MSG}"
  echo "[backup] Committed: ${COMMIT_MSG}"
fi

# ── 6. Push ──────────────────────────────────────────────────────────────────
echo "[backup] Pushing to ${REMOTE} …"
git push "${REMOTE}" HEAD

echo "[backup] Done. Sanitized config: ${SANITIZED_DIR}/openclaw.sanitized.json"
echo ""
echo "To verify no credentials were included:"
echo "  jq . ${SANITIZED_DIR}/openclaw.sanitized.json"

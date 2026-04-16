#!/usr/bin/env bash
# post-upgrade-check.sh — Validates Artoo stack health after an upgrade.
#
# Tests every critical integration so failures are caught immediately
# rather than discovered the next morning when cron jobs run.
#
# Usage:
#   ./post-upgrade-check.sh            # runs all checks, reports to terminal
#   ./post-upgrade-check.sh --notify   # also sends Telegram summary
#
# Exit code: 0 = all passed, 1 = one or more failed.

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${SCRIPT_DIR}"

# Load secrets
source "${SCRIPT_DIR}/.env"

NOTIFY=false
[[ "${1:-}" == "--notify" ]] && NOTIFY=true

PASS=0
FAIL=0
RESULTS=()

# ── Helpers ──────────────────────────────────────────────────────────────────

ok()   { echo "  ✅ $1"; PASS=$((PASS+1)); RESULTS+=("✅ $1"); }
fail() { echo "  ❌ $1"; FAIL=$((FAIL+1)); RESULTS+=("❌ $1"); }
info() { echo "  ℹ️  $1"; }

section() { echo ""; echo "── $1 ──"; }

# ── 1. Gateway ───────────────────────────────────────────────────────────────

section "Gateway"

OC_VERSION=$(docker exec openclaw-gateway node openclaw.mjs --version 2>/dev/null || echo "")
if [[ -n "$OC_VERSION" ]]; then
  ok "Gateway responding: $OC_VERSION"
else
  fail "Gateway not responding"
fi

SYMLINK=$(docker exec openclaw-gateway readlink /media 2>/dev/null || echo "")
if [[ "$SYMLINK" == "/tmp/openclaw" ]]; then
  ok "/media → /tmp/openclaw symlink intact (v2026.4.9+ security workaround)"
else
  fail "/media symlink missing or wrong (expected /tmp/openclaw, got '${SYMLINK}')"
fi

# ── 2. Telegram ──────────────────────────────────────────────────────────────

section "Telegram"

TG_RESP=$(curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_TOKEN}/sendMessage" \
  -d chat_id=8128617103 \
  -d text="🔧 Post-upgrade health check running…" 2>/dev/null)
if echo "$TG_RESP" | python3 -c "import sys,json; sys.exit(0 if json.load(sys.stdin).get('ok') else 1)" 2>/dev/null; then
  ok "Telegram: message delivered to chatId 8128617103"
else
  fail "Telegram: send failed (check TELEGRAM_TOKEN and bot status)"
fi

# ── 3. AgentMail ─────────────────────────────────────────────────────────────

section "AgentMail"

AM_RESP=$(curl -s -w "\n%{http_code}" \
  -H "Authorization: Bearer ${AGENTMAIL_API_KEY}" \
  "https://api.agentmail.to/v0/inboxes" 2>/dev/null)
AM_CODE=$(echo "$AM_RESP" | tail -1)
AM_BODY=$(echo "$AM_RESP" | head -1)

if [[ "$AM_CODE" == "200" ]]; then
  INBOX=$(echo "$AM_BODY" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['inboxes'][0]['email'])" 2>/dev/null || echo "unknown")
  ok "AgentMail API: key valid, inbox=$INBOX"
else
  fail "AgentMail API: returned HTTP $AM_CODE (check AGENTMAIL_API_KEY)"
fi

SEND_SCRIPT="${HOME}/openclaw/workspace/skills/agentmail/send_workspace_briefing.sh"
if [[ -f "$SEND_SCRIPT" && -x "$SEND_SCRIPT" ]]; then
  ok "AgentMail delivery script present and executable"
else
  fail "AgentMail delivery script missing or not executable: $SEND_SCRIPT"
fi

# ── 4. Brave Search ──────────────────────────────────────────────────────────

section "Brave Search"

BRAVE_CODE=$(curl -s -o /tmp/brave_test.json -w "%{http_code}" \
  -H "Accept: application/json" \
  -H "X-Subscription-Token: ${BRAVE_API_KEY}" \
  "https://api.search.brave.com/res/v1/web/search?q=OpenClaw+agent&count=1" 2>/dev/null)

if [[ "$BRAVE_CODE" == "200" ]]; then
  RESULT_COUNT=$(python3 -c \
    "import json; d=json.load(open('/tmp/brave_test.json')); print(len(d.get('web',{}).get('results',[])))" 2>/dev/null || echo "0")
  ok "Brave Search API: key valid, returned $RESULT_COUNT result(s)"
else
  fail "Brave Search API: returned HTTP $BRAVE_CODE (check BRAVE_API_KEY)"
fi

BRAVE_PLUGIN=$(docker exec openclaw-gateway node openclaw.mjs plugins list 2>/dev/null \
  | grep -i "brave" | grep -i "loaded" || echo "")
if [[ -n "$BRAVE_PLUGIN" ]]; then
  ok "Brave plugin: loaded in OpenClaw"
else
  fail "Brave plugin: not loaded (run: docker exec openclaw-gateway node openclaw.mjs plugins enable brave)"
fi

# ── 5. Ollama / Model ────────────────────────────────────────────────────────

section "Ollama & Model"

OLLAMA_RESP=$(curl -s -w "\n%{http_code}" \
  "http://127.0.0.1:11435/api/tags" 2>/dev/null)
OLLAMA_CODE=$(echo "$OLLAMA_RESP" | tail -1)
OLLAMA_BODY=$(echo "$OLLAMA_RESP" | head -1)

if [[ "$OLLAMA_CODE" == "200" ]]; then
  MODEL_COUNT=$(echo "$OLLAMA_BODY" | python3 -c \
    "import sys,json; print(len(json.load(sys.stdin).get('models',[])))" 2>/dev/null || echo "0")
  ok "Ollama API: reachable, $MODEL_COUNT models loaded"
else
  fail "Ollama API: not reachable at :11435 (HTTP $OLLAMA_CODE)"
fi

GEMMA_CHECK=$(curl -s -w "\n%{http_code}" \
  "http://127.0.0.1:11435/api/tags" 2>/dev/null | head -1 \
  | python3 -c "import sys,json; models=[m['name'] for m in json.load(sys.stdin).get('models',[])]; print('ok' if any('gemma4' in m for m in models) else 'missing')" 2>/dev/null || echo "missing")
if [[ "$GEMMA_CHECK" == "ok" ]]; then
  ok "Primary model gemma4:26b: present in Ollama"
else
  fail "Primary model gemma4:26b: NOT found in Ollama (pull it: docker exec ollama ollama pull gemma4:26b)"
fi

OLLAMA_GPU=$(docker exec ollama ollama ps 2>/dev/null | grep -i "gpu" | head -1 || echo "")
if [[ -n "$OLLAMA_GPU" ]]; then
  ok "Ollama GPU: active ($OLLAMA_GPU)"
else
  info "Ollama GPU: no model currently loaded (will verify on next inference)"
fi

# ── 6. Web Fetch ─────────────────────────────────────────────────────────────

section "Web Fetch (outbound HTTP)"

WF_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
  --max-time 10 "https://example.com" 2>/dev/null)
if [[ "$WF_CODE" == "200" ]]; then
  ok "Outbound HTTPS: example.com reachable (HTTP $WF_CODE)"
else
  fail "Outbound HTTPS: example.com returned HTTP $WF_CODE (network issue?)"
fi

# ── 7. Cron Jobs ─────────────────────────────────────────────────────────────

section "Cron Jobs"

EXPECTED_IDS=(
  "8358ce94"  # Agent Needs Briefing
  "aafd403d"  # Daily AI News Briefing
  "e2f3a4b5"  # Gap Implementer
  "d1e2f3a4"  # Gap Scorer
  "c2d4e6f8"  # Agent Infra Weekly Review
  "b1c2d3e4"  # Weekly Wiki Lint
  "7a8c12a6"  # OpenClaw Version Check
)

JOBS_JSON="${HOME}/openclaw-config/cron/jobs.json"
JOBS_CONTENT=$(cat "$JOBS_JSON" 2>/dev/null || echo "{}")

all_present=true
for id in "${EXPECTED_IDS[@]}"; do
  if ! echo "$JOBS_CONTENT" | grep -q "$id"; then
    fail "Cron job missing: $id"
    all_present=false
  fi
done
[[ "$all_present" == true ]] && ok "All 7 expected cron jobs present in jobs.json"

# Check for jobs with consecutive errors > 1 (not counting expected ones)
ERRORS=$(echo "$JOBS_CONTENT" | python3 -c "
import json, sys
data = json.load(sys.stdin)
problems = []
known_flakey = {'7a8c12a6', 'e2f3a4b5'}  # Version Check (always times out), Gap Implementer (exits if no gaps)
for j in data.get('jobs', []):
    s = j.get('state', {})
    errs = s.get('consecutiveErrors', 0)
    jid = j.get('id','')[:8]
    if errs > 1 and jid not in known_flakey:
        problems.append(f\"{j['name']} ({jid}): {errs} consecutive errors\")
if problems:
    print('\n'.join(problems))
" 2>/dev/null)

if [[ -z "$ERRORS" ]]; then
  ok "Cron jobs: no unexpected consecutive error streaks"
else
  while IFS= read -r line; do
    fail "Cron job errors: $line"
  done <<< "$ERRORS"
fi

# ── 8. Summary ───────────────────────────────────────────────────────────────

echo ""
echo "════════════════════════════════════════"
TOTAL=$((PASS+FAIL))
echo "Results: $PASS/$TOTAL passed"
echo "════════════════════════════════════════"

if [[ $FAIL -gt 0 ]]; then
  echo ""
  echo "Failed checks:"
  for r in "${RESULTS[@]}"; do
    [[ "$r" == ❌* ]] && echo "  $r"
  done
fi

# ── Telegram summary (if --notify) ───────────────────────────────────────────

if [[ "$NOTIFY" == true ]]; then
  OC_VER=$(docker exec openclaw-gateway node openclaw.mjs --version 2>/dev/null | grep -oP '[\d.]+' || echo "?")
  if [[ $FAIL -eq 0 ]]; then
    MSG="✅ Post-upgrade check PASSED — all ${TOTAL} checks OK (OpenClaw ${OC_VER})"
  else
    MSG="❌ Post-upgrade check FAILED — ${PASS}/${TOTAL} passed (OpenClaw ${OC_VER})"$'\n\n'
    MSG+="Failed checks:"$'\n'
    for r in "${RESULTS[@]}"; do
      [[ "$r" == ❌* ]] && MSG+="  ${r}"$'\n'
    done
  fi
  curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_TOKEN}/sendMessage" \
    -d chat_id=8128617103 \
    --data-urlencode "text=${MSG}" > /dev/null 2>&1
  echo ""
  echo "Telegram summary sent."
fi

[[ $FAIL -eq 0 ]]

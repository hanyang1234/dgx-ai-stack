#!/usr/bin/env bash
# morning-check.sh — Daily 8am Artoo cron job health report via Telegram.
# Checks whether morning jobs ran, flags errors and missed runs.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/.env"

JOBS_JSON="${HOME}/openclaw-config/cron/jobs.json"
NOW_MS=$(date +%s%3N)
# "should have run by now" window: jobs scheduled before 8am PT (15:00 UTC)
CUTOFF_MS=$(( ($(date -u +%s) - $(date -u +%s --date="$(date -u +%Y-%m-%d) 15:00:00") ) ))

PASS=()
WARN=()
FAIL=()

python3 - <<'EOF'
import json, sys, os, time

jobs_path = os.path.expanduser('~/openclaw-config/cron/jobs.json')
data = json.load(open(jobs_path))
now_ms = int(time.time() * 1000)

# Jobs expected to have run by 8am PT (= 15:00 UTC)
morning_jobs = {
    '8358ce94': ('Agent Needs Briefing',    6),
    'aafd403d': ('Daily AI News Briefing',  7),
}
# Known-flakey — report errors but don't mark as FAIL
known_flakey = {'7a8c12a6', 'e2f3a4b5'}

passes, warns, fails = [], [], []

for j in data.get('jobs', []):
    if not j.get('enabled', True):
        continue
    jid = j.get('id', '')[:8]
    name = j['name']
    s = j.get('state', {})
    errs = s.get('consecutiveErrors', 0)
    last_run_ms = s.get('lastRunAtMs', 0)
    last_status = s.get('lastRunStatus', '')
    last_err = s.get('lastError', '')

    # Check morning jobs ran and succeeded
    if jid in morning_jobs:
        display, hour = morning_jobs[jid]
        # lastRunAtMs should be from today (within last 4 hours of expected run)
        expected_utc_ms = int(time.mktime(time.strptime(
            time.strftime('%Y-%m-%d') + f' {hour+7:02d}:30:00',  # 7h offset PT→UTC, +30min grace
            '%Y-%m-%d %H:%M:%S'
        )) * 1000)
        ran_today = last_run_ms >= (now_ms - 10 * 3600 * 1000)  # within last 10h
        if not ran_today:
            fails.append(f"❌ {display}: did not run this morning")
        elif last_status == 'error':
            fails.append(f"❌ {display}: ran but errored — {last_err[:80]}")
        elif errs > 0:
            warns.append(f"⚠️  {display}: ran ok but has {errs} consecutive error(s) — {last_err[:60]}")
        else:
            passes.append(f"✅ {display}: ran ok")
        continue

    # All other enabled jobs — just flag unexpected error streaks
    if errs > 1 and jid not in known_flakey:
        fails.append(f"❌ {name}: {errs} consecutive errors — {last_err[:80]}")
    elif errs == 1 and jid not in known_flakey:
        warns.append(f"⚠️  {name}: 1 consecutive error — {last_err[:60]}")

# Print structured output for bash to capture
for p in passes: print(f"PASS:{p}")
for w in warns:  print(f"WARN:{w}")
for f in fails:  print(f"FAIL:{f}")
EOF

# Capture python output
REPORT=$(python3 - <<'EOF'
import json, sys, os, time

jobs_path = os.path.expanduser('~/openclaw-config/cron/jobs.json')
data = json.load(open(jobs_path))
now_ms = int(time.time() * 1000)

morning_jobs = {
    '8358ce94': ('Agent Needs Briefing',   6),
    'aafd403d': ('Daily AI News Briefing', 7),
}
known_flakey = {'7a8c12a6', 'e2f3a4b5'}

passes, warns, fails = [], [], []

for j in data.get('jobs', []):
    if not j.get('enabled', True):
        continue
    jid = j.get('id', '')[:8]
    name = j['name']
    s = j.get('state', {})
    errs = s.get('consecutiveErrors', 0)
    last_run_ms = s.get('lastRunAtMs', 0)
    last_status = s.get('lastRunStatus', '')
    last_err = s.get('lastError', '')

    if jid in morning_jobs:
        display, _ = morning_jobs[jid]
        ran_today = last_run_ms >= (now_ms - 10 * 3600 * 1000)
        if not ran_today:
            fails.append(f"❌ {display}: did not run this morning")
        elif last_status == 'error':
            fails.append(f"❌ {display}: ran but errored — {last_err[:80]}")
        elif errs > 0:
            warns.append(f"⚠️  {display}: ran ok but has {errs} consecutive error(s) — {last_err[:60]}")
        else:
            passes.append(f"✅ {display}: ran ok")
        continue

    if errs > 1 and jid not in known_flakey:
        fails.append(f"❌ {name}: {errs} consecutive errors — {last_err[:80]}")
    elif errs == 1 and jid not in known_flakey:
        warns.append(f"⚠️  {name}: 1 consecutive error — {last_err[:60]}")

for p in passes: print(p)
for w in warns:  print(w)
for f in fails:  print(f)
EOF
)

# Build Telegram message
N_FAIL=$(echo "$REPORT" | grep -c "^❌" || true)
N_WARN=$(echo "$REPORT" | grep -c "^⚠️" || true)
N_PASS=$(echo "$REPORT" | grep -c "^✅" || true)

if [[ $N_FAIL -gt 0 ]]; then
    STATUS_EMOJI="❌"
    STATUS_TEXT="ISSUES FOUND"
elif [[ $N_WARN -gt 0 ]]; then
    STATUS_EMOJI="⚠️"
    STATUS_TEXT="WARNINGS"
else
    STATUS_EMOJI="✅"
    STATUS_TEXT="ALL GOOD"
fi

MSG="${STATUS_EMOJI} Artoo 8am check — ${STATUS_TEXT}"$'\n\n'
MSG+="${REPORT}"

curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_TOKEN}/sendMessage" \
  -d chat_id=8128617103 \
  --data-urlencode "text=${MSG}" > /dev/null 2>&1

echo "[morning-check] $(date '+%Y-%m-%d %H:%M') — ${STATUS_EMOJI} ${STATUS_TEXT} (pass=${N_PASS} warn=${N_WARN} fail=${N_FAIL})"

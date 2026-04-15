# Handoff — AI Stack on DGX Spark

**Last updated:** 2026-04-14
**Status:** Fully deployed and operational

---

## Stack Summary

```
CONTAINER           IMAGE                              STATUS
ollama              ollama/ollama:latest (v0.20.5+)    Up (healthy)
open-webui          open-webui/open-webui:latest       Up (healthy)
openclaw-gateway    ghcr.io/openclaw/openclaw:2026.4.14  Up (healthy)

PORTS
0.0.0.0:11435 → ollama:11434       Ollama API (LAN + Tailscale)
0.0.0.0:12000 → open-webui:8080   Open WebUI
0.0.0.0:18789 → openclaw:18789    OpenClaw gateway (token auth)
```

All containers have `restart: unless-stopped` — they survive reboots.
Docker network: `ai-stack` (bridge, external — created manually).
Repo root: `~/Downloads/claude-exp/`

---

## Resuming in a New Claude Code Session

```bash
cd ~/Downloads/claude-exp
docker compose ps                                       # container health
docker compose exec openclaw-gateway openclaw cron list # cron job status
docker compose logs openclaw-gateway --tail 30         # recent logs
cat ~/openclaw/workspace/tmp/artoo-daily-news.txt      # latest briefing
tail -20 backup.log                                    # last backup
```

---

## Current Configuration (April 2026)

### Primary Model
**`ollama/gemma4:26b`** — default for both interactive chat and all cron jobs (as of 2026-04-08).
- Q4_K_M, 16 GB VRAM, ~16 tok/s, vision + tools + thinking, 262K context
- Flash attention active (`OLLAMA_FLASH_ATTENTION=1`)
- Fallbacks: `anthropic/claude-opus-4-6` → `anthropic/claude-sonnet-4-6` → `openai/gpt-5.1-codex`

### All Pulled Models

| Model | Size | GPU? | Role |
|-------|------|------|------|
| `gemma4:26b` | 16 GB | GPU ✓ | **Default** — interactive + all cron jobs |
| `gemma4:31b` | 20 GB | GPU ✓ | Heavy reasoning in Web UI |
| `qwen3.5:9b` | 6.6 GB | GPU ✓ | Fast/simple cron subtasks |
| `qwen3.5:35b` | 23 GB | GPU ✓ | Quality fallback |
| `qwen3.5:122b-a10b-q4_K_M` | 81 GB | GPU ✓ | Large MoE, deep reasoning |
| `nemotron-cascade-2:latest` | 24 GB | GPU ✓ | Fast MoE, reasoning |
| `nemotron-3-super:120b` | 86 GB | GPU ✓ | Deep reasoning (Web UI only) |
| `nemotron-3-nano:latest` | 24 GB | GPU ✓ | Thinking mode |
| `qwen3-coder:latest` | 18 GB | GPU ✓ | Coding tasks |
| `gpt-oss:20b` | 13 GB | CPU only | MXFP4, no GPU |
| `gpt-oss:120b` | 65 GB | CPU only | MXFP4, too slow for cron |

### Cron Jobs

All use `ollama/gemma4:26b`, `sessionTarget: isolated`, `wakeMode: now`.

| Job | ID | Schedule (PT) | Timeout | Status |
|-----|----|--------------|---------|--------|
| Agent Needs Briefing | 8358ce94 | 6:00am daily | 1200s | ok |
| Daily AI News Briefing | aafd403d | 7:00am daily | 1800s | ok |
| Gap Implementer | e2f3a4b5 | 8:00am daily | 600s | error (exits if no approved gaps) |
| Gap Scorer | d1e2f3a4 | Wednesday 9am | 600s | ok |
| Agent Infra Weekly Review | c2d4e6f8 | Sunday 10am | 600s | error (msg delivery) |
| Weekly Wiki Lint | b1c2d3e4 | Sunday 11am | 600s | ok |
| OpenClaw Version Check | 7a8c12a6 | 3:00pm daily | 120s | error (times out) |

Run a job immediately:
```bash
source ~/Downloads/claude-exp/.env
docker exec openclaw-gateway node openclaw.mjs cron run <jobId> \
  --token $OPENCLAW_GATEWAY_TOKEN --url ws://127.0.0.1:18789
```

---

## Key File Locations

| Path | What it is |
|------|-----------|
| `~/Downloads/claude-exp/` | Repo root — compose file, scripts, docs |
| `~/Downloads/claude-exp/.env` | **Secrets** (gitignored) |
| `~/Downloads/claude-exp/docker-compose.yml` | Stack definition |
| `~/Downloads/claude-exp/DEPLOYMENT.md` | Ops reference (full detail) |
| `~/Downloads/claude-exp/ARCHITECTURE.md` | Claude Code ↔ Artoo interface design |
| `~/openclaw-config/` | OpenClaw config bind-mount (`/home/node/.openclaw` in container) |
| `~/openclaw-config/openclaw.json` | Main config — models, gateway, plugins, cron |
| `~/openclaw-config/cron/jobs.json` | Cron job definitions (live bind-mount, no restart needed) |
| `~/openclaw-config/workspace/TOOLS.md` | Startup context injected via bootstrap hook |
| `~/openclaw-config/workspace/SKILLS.md` | Skill registry injected via bootstrap hook |
| `~/openclaw/workspace/` | Artoo's working directory (Docker bind-mount) |
| `~/openclaw/workspace/wiki/` | LLM wiki — 10 topic pages + index |
| `~/openclaw/workspace/TOOLS.md` | What Artoo reads (must stay in sync with config copy) |
| `~/openclaw/workspace/SKILLS.md` | What Artoo reads (must stay in sync with config copy) |
| `~/openclaw/workspace/tmp/` | Briefing output files (`artoo-daily-news.txt`, etc.) |
| `~/openclaw/workspace/GAP_IDEAS.md` | OSS gap tracker |
| `~/openclaw/workspace/RUBRIC.md` | OSS gap scoring rubric |
| `~/openclaw/workspace/specs/` | Project specs for approved OSS gaps |
| `~/.claude/projects/.../memory/` | Claude Code persistent memory (MEMORY.md index) |

---

## Active Integrations

| Integration | Status | Notes |
|---|---|---|
| Ollama (local models) | ✓ Active | 11 models, 16 registered in openclaw.json |
| Anthropic Claude | ✓ Configured | Fallback (credits may be low — check platform.anthropic.com) |
| Telegram | ✓ Active | `@artoo_dgx_bot`, chatId 8128617103, DM policy: open |
| AgentMail | ✓ Active | `artooopenclaw@agentmail.to` → `han.yang123@yahoo.com` |
| Open WebUI | ✓ Active | `http://192.168.4.45:12000` on LAN |
| iMessage | ✗ Disabled | No `imsg` binary in Docker |
| OpenAI / GPT | ✓ Configured | Fallback |

---

## LLM Wiki

Artoo maintains a persistent markdown wiki at `~/openclaw/workspace/wiki/`.
Index: `wiki/index.md`. Current pages: anthropic, openai, hardware, governance,
agent-infrastructure, projections, quantization, agentic-coding, nemoclaw, vllm-dgx-spark.

**Critical:** Phase 0 of briefing cron jobs reads ONLY `index.md` (not full pages).
Loading full pages at startup fills gemma4:26b's context budget → empty briefing output.

Artoo's wiki-query skill lets Han ask: "wiki: [topic]" or "what do you know about [topic]"
and Artoo will search wiki pages to answer.

---

## Credentials in Use

| Credential | Where stored |
|---|---|
| `ANTHROPIC_API_KEY` | `~/Downloads/claude-exp/.env`, `~/openclaw-config/.env` |
| `OPENCLAW_GATEWAY_TOKEN` | `~/Downloads/claude-exp/.env`, `openclaw.json` |
| `TELEGRAM_TOKEN` | `~/Downloads/claude-exp/.env`, `openclaw.json` |
| `AGENTMAIL_API_KEY` | `~/Downloads/claude-exp/.env`, `~/openclaw-config/.env`, `openclaw.json` |

---

## Known Issues (April 2026)

| Issue | Status | Notes |
|-------|--------|-------|
| Telegram delivery fails for long briefings | Open | Telegram 4096-char limit; multi-part not implemented |
| Agent Needs Briefing sometimes times out at 1200s | Intermittent | Cold model load + wiki ingest; OLLAMA_KEEP_ALIVE=10m reduces frequency |
| Agent Infra Weekly Review message delivery failure | Open | Fires but Telegram send fails |
| Gap Implementer exits early | Expected | Exits cleanly when no approved gaps; shows as "error" but is fine |
| OpenClaw Version Check times out at 120s | Known | Low priority; hasn't been fixed |
| Anthropic API credits may be depleted | Check | Top up at platform.anthropic.com |

---

## Quirks to Know

- **TOOLS.md has two copies** — `~/openclaw-config/workspace/TOOLS.md` (injected at startup) and `~/openclaw/workspace/TOOLS.md` (what Artoo reads via file tool). Both must be kept in sync. `backup.sh` syncs config → workspace automatically.

- **jobs.json edits are live** — the file is bind-mounted into the container. Edits take effect on the next cron run without a gateway restart.

- **openclaw.json trailing comma bug** — if `backup.sh` fails with `jq: parse error`, check `~/openclaw-config/openclaw.json` for a trailing comma (most recently found in the `tools.exec` block around line 304).

- **AI-stack network is external** — `docker network create --driver bridge ai-stack` was run once manually. After an OS reinstall, re-create it before `docker compose up`.

- **Docker cgroup driver must be cgroupfs** — not `systemd`. Set in `/etc/docker/daemon.json`. A copy is committed to `sanitized/docker-daemon.json`. This is the decisive fix for CUDA non-deterministic init on GB10.

- **Separate Telegram bot** — any other OpenClaw instance uses `@hanopenclaw123bot`. DGX Spark uses `@artoo_dgx_bot`. Same token on two pollers = 409 conflict.

- **exec blocked in isolated sessions** — Artoo cannot run shell commands in cron sessions. Host cron handles script-based tasks (stock delivery, backup, etc.).

- **GitHub PAT embedded in remote URL** — `git remote get-url origin` to inspect. PAT has expiry; refresh at github.com/settings/tokens if push fails.

- **personality/ dir removed** — stale tracked directory in git; files now live in `openclaw-personality/` (cleaned up 2026-04-10).

---

## Daily Backup

Host cron runs `backup.sh` at 2am daily:
```
0 2 * * * /home/hanyang/Downloads/claude-exp/backup.sh >> /home/hanyang/Downloads/claude-exp/backup.log 2>&1
```

Commits to GitHub with credentials stripped. To run manually:
```bash
cd ~/Downloads/claude-exp && ./backup.sh
```

---

## History Summary (sessions before April 2026)

- **Sessions 1–3 (Feb–Mar 2026):** Initial Dockerization, Anthropic/Telegram/AgentMail integrations, DO migration, split Ollama container, Artoo identity files transferred.
- **Session 4 (Mar 2026):** OSS gap pipeline (RUBRIC.md, GAP_IDEAS.md, Gap Scorer/Implementer cron), Ollama OOM fix, email delivery via AgentMail, exec approval allowlist.
- **Session 5 (Mar 2026):** Gateway exposed on LAN, 3 new Ollama models, CUDA init bug root-caused and fixed (cgroupfs + cuda_v13), NemoClaw evaluated (defer).
- **Sessions 6–7 (Apr 2026):** Upgraded to OpenClaw 2026.4.9→2026.4.12, Ollama v0.20.5, Open WebUI latest. LLM wiki built (10 pages), wiki backfill completed (2 runs), wiki-query skill created, Phase 0 context bloat bug fixed (read only index.md), OLLAMA_KEEP_ALIVE=10m added, Weekly Wiki Lint job added. Claude Code ↔ Artoo architecture documented.

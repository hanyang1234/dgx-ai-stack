# Handoff — AI Stack on DGX Spark

**Last updated:** 2026-03-11
**Status:** Fully deployed and operational — no manual steps remaining

---

## Stack Summary

```
CONTAINER           STATUS          PORTS
open-webui          Up (healthy)    0.0.0.0:12000→8080, 127.0.0.1:11435→11434
openclaw-gateway    Up (healthy)    127.0.0.1:18789→18789
```

Both containers have `restart: unless-stopped` — they survive reboots automatically.

---

## What Was Deployed (Across Three Sessions)

### Session 1 — Initial Dockerization
1. Upgraded Open WebUI to `ghcr.io/open-webui/open-webui:ollama` with `OLLAMA_HOST=0.0.0.0:11434`
2. Deployed OpenClaw v2026.3.8 in Docker (`ghcr.io/openclaw/openclaw:latest`)
3. Migrated native OpenClaw config (`~/.openclaw/` → `~/openclaw-config/`) to Docker bind-mount
4. Wired OpenClaw to bundled Ollama via `http://open-webui:11434` (ai-stack network)
5. Reset Open WebUI admin password (`han.yang123@yahoo.com` / `changeme123` — **change this**)
6. Set up GitHub repo (`hanyang1234/dgx-ai-stack`) with `backup.sh`, `restore.sh`, `update.sh`, etc.
7. Configured daily 2am host cron: `0 2 * * * /home/hanyang/Downloads/claude-exp/backup.sh`

### Session 2 — Integrations and Hardening
8. Configured Anthropic auth via `~/openclaw-config/agents/main/agent/auth-profiles.json`
9. Added `ANTHROPIC_API_KEY` and `TELEGRAM_TOKEN` to `~/openclaw-config/.env`
10. Enabled Telegram plugin — initial bot `@hanopenclaw123bot` (DO instance conflict)
11. Installed and activated **AgentMail** skill (`✓ ready`) with API key configured

### Session 3 — DO Migration and Tuning
12. Created separate Telegram bot `@artoo_dgx_bot` to avoid 409 conflict with DO instance
13. Set Telegram DM policy to `open` with `allowFrom: ["*"]`
14. Transferred identity files from DO: `SOUL.md`, `USER.md`, `IDENTITY.md` → `~/openclaw-config/workspace/`
15. Transferred 3 OpenClaw cron jobs from DO: `~/openclaw-config/cron/jobs.json`
    - Agent Needs Briefing — 6:00am daily
    - Daily AI News Briefing — 6:30am daily
    - OpenClaw Version Check — 3:00pm daily
16. Pulled `qwen3.5:35b` (23 GB) and set as primary model
17. Disabled Nemotron thinking mode as primary (leaks chain-of-thought to Telegram)

---

## Credentials in Use

| Credential | Where stored | Notes |
|---|---|---|
| `ANTHROPIC_API_KEY` | `~/Downloads/claude-exp/.env`, `~/openclaw-config/.env`, `auth-profiles.json` | Fallback LLM provider |
| `OPENCLAW_GATEWAY_TOKEN` | `~/Downloads/claude-exp/.env`, `openclaw.json` | Gateway auth bearer token |
| `TELEGRAM_TOKEN` | `~/Downloads/claude-exp/.env`, `openclaw.json` | Bot token for `@artoo_dgx_bot` |
| `AGENTMAIL_API_KEY` | `~/Downloads/claude-exp/.env`, `~/openclaw-config/.env`, `openclaw.json` | AgentMail email integration |
| Open WebUI password | Not stored — reset to `changeme123` | **Change on next login** |

> **Action required:** Rotate the GitHub PAT used during setup — it was shared in the Claude Code chat session.
> Go to https://github.com/settings/tokens and regenerate the token.

---

## Key File Locations

| Path | What it is |
|------|-----------|
| `~/Downloads/claude-exp/` | Repo root — all scripts and compose file |
| `~/Downloads/claude-exp/.env` | **Secrets** (gitignored) |
| `~/Downloads/claude-exp/docker-compose.yml` | Stack definition |
| `~/openclaw-config/` | OpenClaw config bind-mount (`/home/node/.openclaw` in container) |
| `~/openclaw-config/openclaw.json` | Main config — models, gateway, plugins, skills |
| `~/openclaw-config/.env` | OpenClaw's internal env file — provider API keys |
| `~/openclaw-config/agents/main/agent/auth-profiles.json` | Anthropic API key for OpenClaw auth |
| `~/openclaw-config/workspace/` | Agent personality files (SOUL.md, USER.md, etc.) |
| `~/openclaw-config/cron/jobs.json` | OpenClaw internal cron job definitions |
| `~/openclaw-config/workspace/skills/agentmail/` | AgentMail skill (installed via clawhub) |

---

## Active Integrations

| Integration | Status | Notes |
|---|---|---|
| Ollama (local models) | ✓ Active | 5 models via `http://open-webui:11434` |
| Anthropic Claude | ✓ Active | Fallback provider via auth-profiles.json |
| Telegram | ✓ Active | `@artoo_dgx_bot`, DM policy: open |
| AgentMail | ✓ Active | Email inbox for the agent |
| iMessage | ✗ Disabled | No `imsg` binary in Docker |
| OpenAI / GPT | ✓ Configured | Fallback via `openclaw.json` |

---

## Configured Ollama Models

| Model ID | Role | Context |
|---|---|---|
| `ollama/qwen3.5:35b` | **Primary** — general chat | 65k tokens |
| `ollama/gpt-oss:120b` | Large reasoning | 65k tokens |
| `ollama/gpt-oss:20b` | Subagents / fast | 65k tokens |
| `ollama/qwen3-coder:latest` | Coding | 65k tokens |
| `ollama/nemotron-3-nano:latest` | Reasoning (not primary — leaks thinking to Telegram) | 128k tokens |

---

## OpenClaw Cron Jobs (Internal)

| Job | Schedule | Model |
|---|---|---|
| Agent Needs Briefing | 6:00am daily (America/Los_Angeles) | anthropic/claude-* |
| Daily AI News Briefing | 6:30am daily (America/Los_Angeles) | — |
| OpenClaw Version Check | 3:00pm daily (America/Los_Angeles) | — |

View with: `docker compose exec openclaw-gateway openclaw cron list`

---

## Ports

| Port | Bind | What |
|------|------|------|
| `12000` | `0.0.0.0` | Open WebUI (public) |
| `11434` | `0.0.0.0` | **Native** host Ollama (separate process) |
| `11435` | `127.0.0.1` | Container Ollama inside open-webui |
| `18789` | `127.0.0.1` | OpenClaw gateway |

---

## Quirks to Know

- **Separate Telegram bot** — DO instance uses `@hanopenclaw123bot`. DGX uses `@artoo_dgx_bot`. Using the same token on two instances causes a 409 conflict; each instance needs its own bot.

- **Nemotron thinking mode leaks** — Nemotron-3 with `thinking: true` sends its chain-of-thought reasoning to Telegram as visible text. Keep it as a non-primary model or use it only for isolated agent tasks.

- **Port 11434 conflict** — the host has a native `ollama serve` process that holds `0.0.0.0:11434`. The container's Ollama is mapped to `11435` on the host but reachable internally at `http://open-webui:11434`. Don't stop the native Ollama unless you know what depends on it.

- **Native OpenClaw is disabled** — `~/.config/systemd/user/openclaw-gateway.service` still exists but is disabled. Do not re-enable it; it conflicts with Docker on port 18789.

- **OLLAMA_HOST env var is required** — without `OLLAMA_HOST=0.0.0.0:11434` in the open-webui container, Ollama binds to loopback only and OpenClaw cannot reach it.

- **jq edits to openclaw.json** — use `docker compose exec openclaw-gateway openclaw config set` or edit the file directly with the Write tool. Never use shell redirects (`>`) to edit it — a failed `mv` will truncate the file to 0 bytes.

---

## Daily Backup

A host cron job runs `backup.sh` every day at 2am:
```
0 2 * * * /home/hanyang/Downloads/claude-exp/backup.sh >> /home/hanyang/Downloads/claude-exp/backup.log 2>&1
```

Backup commits to `hanyang1234/dgx-ai-stack` on GitHub. Credentials are stripped before commit.

To run manually:
```bash
cd ~/Downloads/claude-exp && ./backup.sh
```

---

## Resuming in a New Claude Code Session

```bash
cd ~/Downloads/claude-exp
# Claude Code will load DEPLOYMENT.md and HANDOFF.md for context automatically
```

Useful commands to orient yourself:
```bash
docker compose ps                                                    # container health
docker compose exec openclaw-gateway openclaw skills list           # skill status
docker compose exec openclaw-gateway openclaw cron list             # internal cron jobs
docker compose logs openclaw-gateway --tail 30                      # recent logs
crontab -l                                                           # host cron jobs
tail -20 backup.log                                                  # last backup run
```

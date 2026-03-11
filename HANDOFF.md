# Handoff — AI Stack on DGX Spark

**Last updated:** 2026-03-11
**Status:** Fully deployed and operational — no manual steps remaining

---

## Stack Summary

Everything is running. The stack consists of two Docker containers on the `ai-stack` bridge network:

```
CONTAINER           STATUS          PORTS
open-webui          Up (healthy)    0.0.0.0:12000→8080, 127.0.0.1:11435→11434
openclaw-gateway    Up (healthy)    127.0.0.1:18789→18789
```

Both containers have `restart: unless-stopped` — they survive reboots automatically.

---

## What Was Deployed (Across Two Sessions)

### Session 1 — Initial Dockerization
1. Upgraded Open WebUI to `ghcr.io/open-webui/open-webui:ollama` with `OLLAMA_HOST=0.0.0.0:11434`
2. Deployed OpenClaw v2026.3.8 in Docker (`ghcr.io/openclaw/openclaw:latest`)
3. Migrated native OpenClaw config (`~/.openclaw/` → `~/openclaw-config/`) to Docker bind-mount
4. Wired OpenClaw to bundled Ollama via `http://open-webui:11434` (ai-stack network)
5. Reset Open WebUI admin password (`han.yang123@yahoo.com` / `changeme123` — **change this**)
6. Set up GitHub repo (`hanyang1234/dgx-ai-stack`) with `backup.sh`, `restore.sh`, `update.sh`, etc.
7. Configured daily 2am cron: `0 2 * * * /home/hanyang/Downloads/claude-exp/backup.sh`

### Session 2 — Integrations and Hardening
8. Set primary model to **Nemotron-3 Nano in thinking mode** (`ollama/nemotron-3-nano:latest`)
   - Fallbacks: claude-opus-4-6 → claude-sonnet-4-6 → gpt-5.1-codex
9. Configured Anthropic auth via `~/openclaw-config/agents/main/agent/auth-profiles.json`
10. Added `ANTHROPIC_API_KEY` and `TELEGRAM_TOKEN` to `~/openclaw-config/.env`
11. Enabled Telegram plugin — bot running as `@hanopenclaw123bot`
12. Installed and activated **AgentMail** skill (`✓ ready`) with API key configured

---

## Credentials in Use

| Credential | Where stored | Notes |
|---|---|---|
| `ANTHROPIC_API_KEY` | `~/Downloads/claude-exp/.env`, `~/openclaw-config/.env`, `auth-profiles.json` | Fallback LLM provider |
| `OPENCLAW_GATEWAY_TOKEN` | `~/Downloads/claude-exp/.env`, `openclaw.json` | Gateway auth bearer token |
| `TELEGRAM_TOKEN` | `~/Downloads/claude-exp/.env`, `openclaw.json` | Bot token for `@hanopenclaw123bot` |
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
| `~/openclaw/workspace/` | Agent working directory |
| `~/openclaw-config/workspace/skills/agentmail/` | AgentMail skill (installed via clawhub) |

---

## Active Integrations

| Integration | Status | Notes |
|---|---|---|
| Ollama (local models) | ✓ Active | 4 models via `http://open-webui:11434` |
| Anthropic Claude | ✓ Active | Fallback provider via auth-profiles.json |
| Telegram | ✓ Active | `@hanopenclaw123bot`, DM policy: pairing |
| AgentMail | ✓ Active | Email inbox for the agent |
| iMessage | ✗ Disabled | No `imsg` binary in Docker |
| OpenAI / GPT | ✓ Configured | Fallback via `openclaw.json` |

---

## Configured Ollama Models

| Model ID | Role | Context |
|---|---|---|
| `ollama/nemotron-3-nano:latest` | **Primary** — thinking/reasoning | 128k tokens |
| `ollama/gpt-oss:120b` | Large reasoning | 65k tokens |
| `ollama/gpt-oss:20b` | Subagents / fast | 65k tokens |
| `ollama/qwen3-coder:latest` | Coding | 65k tokens |

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

- **Port 11434 conflict** — the host has a native `ollama serve` process that holds `0.0.0.0:11434`. The container's Ollama is mapped to `11435` on the host but reachable internally at `http://open-webui:11434`. Don't stop the native Ollama unless you know what depends on it.

- **Native OpenClaw is disabled** — `~/.config/systemd/user/openclaw-gateway.service` still exists but is disabled. Do not re-enable it; it conflicts with Docker on port 18789.

- **Telegram group messages are silently dropped** — `groupPolicy` is `allowlist` but `groupAllowFrom` is empty. To allow a group, add its ID to `channels.telegram.groupAllowFrom` in `openclaw.json`.

- **Nemotron streaming is off** — Nemotron-3 runs with `streaming: false` (required for thinking mode). Responses arrive in one shot rather than word-by-word.

- **OLLAMA_HOST env var is required** — without `OLLAMA_HOST=0.0.0.0:11434` in the open-webui container, Ollama binds to loopback only and OpenClaw cannot reach it.

---

## Daily Backup

A cron job runs `backup.sh` every day at 2am:
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
docker compose ps                                          # container health
docker compose exec openclaw-gateway openclaw skills list # skill status
docker compose exec openclaw-gateway openclaw models list # model status
crontab -l                                                 # scheduled jobs
tail -20 backup.log                                        # last backup run
```

# Handoff — AI Stack on DGX Spark

**Last updated:** 2026-03-21
**Status:** Fully deployed and operational — no manual steps remaining

---

## Stack Summary

```
CONTAINER           STATUS          PORTS
open-webui          Up (healthy)    0.0.0.0:12000→8080, 127.0.0.1:11435→11434
openclaw-gateway    Up (healthy)    0.0.0.0:18789→18789
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

### Session 4 — Hardening, OSS Gap Pipeline, Ollama OOM Fix (2026-03-12 to 2026-03-18)
18. **Pinned OpenClaw to v2026.3.11** — v2026.3.12/3.13 crash with Ollama plugin bug
    (`ReferenceError: Cannot access 'ANTHROPIC_MODEL_ALIASES' before initialization`)
19. **Email delivery restored via AgentMail** — `daily-briefing-email.js` script reads
    `AGENT_BRIEFING_FILE` env var (path to temp file). Cron jobs write briefing to `/tmp/artoo-*.txt`
    then exec the script. Both briefing jobs deliver to Telegram + email.
20. **Added exec approval allowlist** — `node *` and `node -e *` pre-approved on the main agent
    to avoid interactive approval prompts during gateway exec calls
21. **Fixed AGENT_INFRA.md GitHub sync** — `backup.sh` was looking at `~/openclaw-config/workspace/`
    but the file lives in `~/openclaw/workspace/` (Docker bind-mount). Added explicit copy block.
22. **Created SKILLS.md** for Artoo's workspace — capability map covering tools, models, cron jobs,
    and contacts; integrated into session startup reading list in `AGENTS.md`
23. **OSS Gap Pipeline (Phase 1 & 2):**
    - Created `RUBRIC.md` — 6-dimension scoring rubric (Pain, Uniqueness, Addressability, Timing,
      Leverage, Han's Edge); score ≥ 7.0 triggers alert to Han
    - Created `GAP_IDEAS.md` — gap tracker seeded with 2 entries from AGENT_INFRA.md
    - Updated Agent Needs Briefing — now extracts [GAP] entries and appends to GAP_IDEAS.md
    - Added **Gap Scorer** cron job (Wednesday 9am PT) — scores unscored gaps, alerts Han for ≥ 7.0
    - Added **Gap Implementer** cron job (daily 8am PT) — writes spec for approved gaps, notifies Han
    - All approval-gated: Han must reply APPROVE → SCAFFOLD before any code ships
    - Updated `backup.sh` to include RUBRIC.md, GAP_IDEAS.md, and `specs/`
24. **Ollama OOM fix** — cron jobs failing with "model requires more system memory (63.4 GiB) than
    available (62.3 GiB)" when a different 120b model was warm from Open WebUI use. Fixed by adding
    `OLLAMA_MAX_LOADED_MODELS=1` to `docker-compose.yml` and restarting `open-webui`.
25. **NemoClaw decision: wait** — requires fresh OpenClaw install (can't layer on existing);
    alpha-stage with active install failures; no DGX Spark-specific guidance. Re-evaluate in 4–6 weeks.

### Session 5 — Model Expansion, Control UI, GPU Fix (2026-03-18 to 2026-03-21)
26. **Gateway exposed on LAN** — changed `gateway.bind` from `loopback` → `lan` and port binding
    from `127.0.0.1:18789` → `0.0.0.0:18789`. Control UI now accessible via browser on LAN or SSH tunnel.
27. **Added 3 new Ollama models** — `qwen3.5:122b-a10b-q4_K_M`, `nemotron-cascade-2:latest`,
    `nemotron-3-super:120b` registered in openclaw.json.
28. **Default conversation model changed to `gpt-oss:20b`** — fastest response for interactive chat.
29. **All cron jobs switched to `ollama/qwen3.5:35b`** — root cause analysis (2026-03-21):
    - gpt-oss models use MXFP4 format which runs **CPU-only** in Ollama v0.17.7 (no GPU offload)
    - gpt-oss:120b at 60.9 GiB on CPU → inference too slow to complete within 10-minute timeout
    - qwen3.5:35b is GGUF, uses GPU (41/41 layers on CUDA0, 21.9 GiB VRAM), loads in ~8s
30. **CUDA non-deterministic init bug discovered** — after container restart, `ggml_cuda_init`
    sometimes fails ("no CUDA-capable device"). Fix: restart `open-webui` a **second** time. GGUF
    models then properly use GPU. Root cause unknown; appears to be a container toolkit race.
31. **Daily AI News Briefing rescheduled** — from 6:30am → 7:00am PT.
32. **Anthropic API credits depleted** — fallback chain breaks on Anthropic models. Top up at
    platform.anthropic.com to restore. OpenAI fallback remains active.

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
| `~/openclaw/workspace/` | Artoo's working directory (Docker bind-mount) |
| `~/openclaw/workspace/AGENT_INFRA.md` | Agent infrastructure knowledge base |
| `~/openclaw/workspace/SKILLS.md` | Artoo's capability map |
| `~/openclaw/workspace/RUBRIC.md` | OSS gap scoring rubric |
| `~/openclaw/workspace/GAP_IDEAS.md` | OSS gap tracker (unscored → shipped) |
| `~/openclaw/workspace/specs/` | Project specs for approved OSS gaps |

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

| Model ID | Role | GPU? | Context |
|---|---|---|---|
| `ollama/gpt-oss:20b` | **Primary** — interactive chat (fast) | CPU only (MXFP4) | 65k |
| `ollama/qwen3.5:35b` | **Cron jobs** — GPU-accelerated quality model | GPU ✓ | 65k |
| `ollama/gpt-oss:120b` | Large reasoning (CPU-only — too slow for cron) | CPU only (MXFP4) | 65k |
| `ollama/qwen3.5:122b-a10b-q4_K_M` | Large MoE | GPU ✓ | 262k |
| `ollama/nemotron-cascade-2:latest` | Fast MoE | GPU ✓ | 262k |
| `ollama/nemotron-3-super:120b` | Nemotron Super | GPU ✓ | 65k |
| `ollama/qwen3-coder:latest` | Coding | GPU ✓ | 65k |
| `ollama/nemotron-3-nano:latest` | Reasoning (not primary — leaks thinking to Telegram) | GPU ✓ | 128k |

> **gpt-oss (MXFP4) models** run CPU-only in Ollama v0.17.7 — they do not offload to GPU.
> gpt-oss:20b is fast enough for short chat (16 GiB on CPU). gpt-oss:120b is too slow for cron.

---

## OpenClaw Cron Jobs (Internal)

| Job | Schedule | Model | Delivery |
|---|---|---|---|
| Agent Needs Briefing | 6:00am daily (PT) | ollama/qwen3.5:35b | Telegram + email |
| Daily AI News Briefing | 7:00am daily (PT) | ollama/qwen3.5:35b | Telegram + email |
| Gap Scorer | Wednesday 9:00am (PT) | ollama/qwen3.5:35b | Telegram (alerts only) |
| Gap Implementer | 8:00am daily (PT) | ollama/qwen3.5:35b | None (silent if no approved gaps) |
| Agent Infra Weekly Review | Sunday 10:00am (PT) | ollama/qwen3.5:35b | Telegram |
| OpenClaw Version Check | 3:00pm daily (PT) | default | None (silent if up to date) |

All jobs use `sessionTarget: isolated` and `wakeMode: now`. Email delivery via AgentMail:
agent writes briefing to `/tmp/artoo-*.txt`, then execs `daily-briefing-email.js`.

View with: `docker compose exec openclaw-gateway openclaw cron list`

---

## Ports

| Port | Bind | What |
|------|------|------|
| `12000` | `0.0.0.0` | Open WebUI (public) |
| `11434` | `0.0.0.0` | **Native** host Ollama (separate process) |
| `11435` | `127.0.0.1` | Container Ollama inside open-webui |
| `18789` | `0.0.0.0` | OpenClaw gateway (LAN-accessible, token auth required) |

---

## Quirks to Know

- **Separate Telegram bot** — DO instance uses `@hanopenclaw123bot`. DGX uses `@artoo_dgx_bot`. Using the same token on two instances causes a 409 conflict; each instance needs its own bot.

- **Nemotron thinking mode leaks** — Nemotron-3 with `thinking: true` sends its chain-of-thought reasoning to Telegram as visible text. Keep it as a non-primary model or use it only for isolated agent tasks.

- **Port 11434 conflict** — the host has a native `ollama serve` process that holds `0.0.0.0:11434`. The container's Ollama is mapped to `11435` on the host but reachable internally at `http://open-webui:11434`. Don't stop the native Ollama unless you know what depends on it.

- **Native OpenClaw is disabled** — `~/.config/systemd/user/openclaw-gateway.service` still exists but is disabled. Do not re-enable it; it conflicts with Docker on port 18789.

- **OLLAMA_HOST env var is required** — without `OLLAMA_HOST=0.0.0.0:11434` in the open-webui container, Ollama binds to loopback only and OpenClaw cannot reach it.

- **OLLAMA_MAX_LOADED_MODELS=1 is required** — the DGX Spark has 128 GiB unified memory. Each 120b model needs ~63 GiB. Without this limit, a warm model from Open WebUI use will cause cron jobs to OOM when trying to load `gpt-oss:120b`. Side effect: model switching in Open WebUI takes 20–30s instead of instant.

- **OpenClaw pinned to v2026.3.11** — do not upgrade to v2026.3.12 or v2026.3.13. Both crash with an Ollama plugin initialization error. Monitor for v2026.3.14+.

- **gpt-oss (MXFP4) models are CPU-only** — gpt-oss:20b and gpt-oss:120b run entirely on CPU in Ollama v0.17.7. gpt-oss:20b is fast enough for interactive chat; gpt-oss:120b at 60.9 GiB on CPU is too slow for cron jobs (10-minute timeout). All cron jobs use `qwen3.5:35b` (GPU-accelerated).

- **CUDA init non-deterministic after container restart** — after restarting `open-webui`, CUDA sometimes fails to initialize (`ggml_cuda_init: failed to initialize CUDA`). Fix: restart `open-webui` a **second** time. Signs of broken CUDA: all models show `offloaded 0/N layers to GPU` and responses take 1+ minute even for "say hi".

- **jq edits to openclaw.json** — use `docker compose exec openclaw-gateway openclaw config set` or edit the file directly with the Write tool. Never use shell redirects (`>`) to edit it — a failed `mv` will truncate the file to 0 bytes.

- **Agent workspace vs config** — `~/openclaw/workspace/` (Docker bind-mount) is Artoo's working directory. `~/openclaw-config/workspace/` is personality/identity files. They are different directories. AGENT_INFRA.md, SKILLS.md, RUBRIC.md, GAP_IDEAS.md all live in `~/openclaw/workspace/`.

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

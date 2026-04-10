# AI Stack Deployment — NVIDIA DGX Spark

> **Living document** — run `./backup.sh` after any stack change to keep this in sync with GitHub.

---

## Stack Overview

```
HOST: NVIDIA DGX Spark GB10 (Ubuntu)
│  NVIDIA driver: 580.142 | nvidia-container-toolkit: v1.19.0
│  Docker cgroup driver: cgroupfs (required for CUDA init — see Troubleshooting)
│  Tailscale IP: 100.105.68.67
│
│  Docker network: ai-stack (bridge)
│  │
│  ├── ollama  (ollama/ollama:latest, v0.20.4+)
│  │   ├── Ollama API         0.0.0.0:11435 → :11434   (LAN + Tailscale accessible)
│  │   ├── Volume: open-webui-ollama        → /root/.ollama  (all model weights)
│  │   ├── Env: OLLAMA_LLM_LIBRARY=cuda_v13     (required for GB10 CUDA init)
│  │   ├── Env: OLLAMA_MAX_LOADED_MODELS=2      (two models in VRAM simultaneously)
│  │   └── Env: OLLAMA_FLASH_ATTENTION=1        (faster prefill/TTFT)
│  │
│  ├── open-webui  (ghcr.io/open-webui/open-webui:latest)
│  │   ├── Open WebUI         0.0.0.0:12000 → :8080
│  │   ├── Volume: open-webui              → /app/backend/data
│  │   └── Env: OLLAMA_BASE_URL=http://ollama:11434
│  │
│  └── openclaw-gateway  (ghcr.io/openclaw/openclaw:2026.4.9)
│      ├── Gateway            0.0.0.0:18789 → :18789   (LAN, token auth)
│      ├── Bind: ~/openclaw-config          → /home/node/.openclaw
│      ├── Bind: ~/openclaw/workspace       → /home/node/workspace
│      └── Startup: runs as root, creates /media→/tmp/openclaw symlink, then drops to node user
│
│  Internal traffic (ai-stack, never leaves Docker):
│      openclaw-gateway → ollama:11434      (Ollama API)
│      open-webui       → ollama:11434      (Ollama API)
```

### Port Map

| Port | Bind | Service | Visible to |
|------|------|---------|------------|
| `12000` | `0.0.0.0` | Open WebUI | LAN / Tailscale |
| `11435` | `0.0.0.0` | Ollama API | LAN / Tailscale (`100.105.68.67:11435`) |
| `18789` | `0.0.0.0` | OpenClaw gateway | LAN (token auth required) |

> **Why separate Ollama container:** The bundled `open-webui:ollama` image caps Ollama at
> v0.18.2, which predates Gemma 4 support. Splitting into `ollama/ollama:latest` allows
> independent Ollama updates. The `open-webui-ollama` named volume is shared between both
> containers so all downloaded models are preserved.

---

## Ollama

**Container:** `ollama/ollama:latest` (standalone, v0.20.4+)

**Critical env vars:**
- `OLLAMA_LLM_LIBRARY=cuda_v13` — forces the correct CUDA library for GB10. Without this, CUDA init is non-deterministic and models may silently fall back to CPU.
- `OLLAMA_MAX_LOADED_MODELS=2` — allows two models resident in VRAM simultaneously. With 128 GiB unified memory, this fits e.g. gemma4:26b (16 GB) + gemma4:31b (20 GB) at the same time, reducing cold-load latency for cron jobs. Keep at 2 rather than higher to avoid OOM with large models.
- `OLLAMA_FLASH_ATTENTION=1` — enables flash attention for all models that support it (gemma4, qwen3.5, nemotron). Reduces time-to-first-token and increases tokens/sec, especially for long context. No quality impact.
- `OLLAMA_KEEP_ALIVE=10m` — evicts models 10 minutes after the last request. Default is 5 minutes. Set to 10m so that large models loaded in Web UI (e.g. nemotron 86 GB) are guaranteed to be gone well before the 6am cron jobs run, eliminating the cold-load + eviction latency that was causing briefing timeouts.

**Host-level requirement:** Docker must use `cgroupfs` cgroup driver (not `systemd`). Set in `/etc/docker/daemon.json`:
```json
{"userland-proxy": false, "exec-opts": ["native.cgroupdriver=cgroupfs"]}
```
This is the decisive fix for non-deterministic CUDA device detection on GB10. A copy is committed to `sanitized/docker-daemon.json`. After any OS reinstall, restore this before starting the stack.

### Named Volumes

| Volume | Container | Path | Contents |
|--------|-----------|------|---------|
| `open-webui` | open-webui | `/app/backend/data` | WebUI database, user settings |
| `open-webui-ollama` | ollama + open-webui | `/root/.ollama` | All model weights (~200 GB+) |

### Pulling new Ollama models

```bash
docker exec ollama ollama pull gemma4:26b
docker exec ollama ollama list
```

### Updating Ollama

```bash
docker compose pull ollama
docker compose up -d --no-deps ollama
docker exec ollama ollama list   # verify models still present
```

### Updating Open WebUI

```bash
./update-webui.sh
```

## Open WebUI

Points to the standalone Ollama container via `OLLAMA_BASE_URL=http://ollama:11434`.
Accessible at `http://192.168.4.45:12000` on LAN.

---

## OpenClaw

### Image version
Pinned to `ghcr.io/openclaw/openclaw:2026.4.9` (updated 2026-04-08).

To update:
```bash
./update.sh
```

### How Ollama models are wired in

OpenClaw connects to the standalone `ollama` container via the internal `ai-stack` Docker network.
The provider block in `~/openclaw-config/openclaw.json`:

```json5
{
  models: {
    providers: {
      ollama: {
        baseUrl: "http://ollama:11434",   // standalone ollama container
        apiKey: "ollama-local",
        api: "ollama",                    // native /api/chat (full tool support)
        models: [...]
      }
    }
  }
}
```

### Configured Ollama models

| OpenClaw model ID | Alias | GPU? | Size | Role |
|---|---|---|---|---|
| `ollama/gemma4:26b` | Gemma4-26B | GPU ✓ | 16 GB | **Default** — interactive chat + all cron jobs |
| `ollama/gemma4:31b` | Gemma4-31B | GPU ✓ | 20 GB | Quality eval / heavy reasoning |
| `ollama/qwen3.5:35b` | Qwen35 | GPU ✓ | 23 GB | Fallback for cron jobs |
| `ollama/qwen3.5:9b` | Qwen9B | GPU ✓ | 6.6 GB | Fast/simple cron subtasks |
| `ollama/nemotron-3-super:120b` | Nemotron-Super | GPU ✓ | 86 GB | Deep reasoning (Web UI only) |
| `ollama/qwen3.5:122b-a10b-q4_K_M` | Qwen122B | GPU ✓ | 81 GB | Large MoE |
| `ollama/nemotron-cascade-2:latest` | Cascade2 | GPU ✓ | 24 GB | Fast MoE, reasoning |
| `ollama/qwen3-coder:latest` | local-coder | GPU ✓ | 18 GB | Coding tasks |
| `ollama/nemotron-3-nano:latest` | Nemotron-Chat | GPU ✓ | 24 GB | Thinking mode |
| `ollama/gpt-oss:20b` | local-fast | CPU only† | 13 GB | Subagents |
| `ollama/gpt-oss:120b` | local-large | CPU only† | 65 GB | Too slow for cron |

† **gpt-oss (MXFP4) models run CPU-only** — do not offload to GPU regardless of VRAM.

Context window: 65,536 tokens for most models; 262,144 for gemma4 (26b and 31b), Cascade-2, and Qwen 122B.

### Primary model

**Gemma4 26B** (`ollama/gemma4:26b`) — default for both interactive chat and all cron jobs (2026-04-08).
Supports vision (image inputs via Telegram), tool use, and thinking mode. Q4_K_M, 16 GB VRAM.
Fallbacks: `anthropic/claude-opus-4-6` → `anthropic/claude-sonnet-4-6` → `openai/gpt-5.1-codex`.

**Model selection for cron jobs:** When creating a new cron job, always confirm which model to use.
- Fast/simple tasks: `ollama/qwen3.5:9b`
- Research/briefing tasks: `ollama/gemma4:26b` (default)
- Deep reasoning: `ollama/qwen3.5:122b-a10b-q4_K_M` or `ollama/nemotron-cascade-2:latest`

**Switch model in chat:** say "use Gemma4" or type `/model ollama/gemma4:26b`.

### How to switch the active model

**Via CLI** (on the host, connects to Docker gateway):
```bash
# Switch to a local Ollama model
openclaw models set ollama/gpt-oss:120b

# Switch back to Claude
openclaw models set anthropic/claude-opus-4-6

# List all configured models
openclaw models list
```

**Via Web UI:**
1. Open `http://127.0.0.1:18789` in a browser
2. Settings → Model → select from dropdown

**For a single agent session only:**
```bash
openclaw agent start --model ollama/gpt-oss:20b
```

### Gateway token

The gateway token authenticates all API/WebSocket requests to OpenClaw.

- Lives in `~/openclaw-config/openclaw.json` under `gateway.auth.token`
- Also stored in `~/Downloads/claude-exp/.env` as `OPENCLAW_GATEWAY_TOKEN` (Docker env)
- Was preserved from the native install — existing TUI/CLI pairings continue to work

To retrieve it:
```bash
jq -r .gateway.auth.token ~/openclaw-config/openclaw.json
```

To reset it:
```bash
openclaw config set gateway.auth.token "$(openssl rand -hex 32)"
docker compose restart openclaw-gateway
```
> All paired clients will need to re-authenticate after a token reset.

### Messaging platform pairing

**Telegram** — configured and running as `@artoo_dgx_bot`:
- Bot token is set in `openclaw.json` under `channels.telegram.botToken`
- Plugin is enabled under `plugins.entries.telegram.enabled: true`
- DM policy: `open` with `allowFrom: ["*"]` (any user can DM)
- Group policy: `allowlist` (add group IDs to `channels.telegram.groupAllowFrom` to enable)

> **Why a separate bot from DO:** The original bot token (`@hanopenclaw123bot`) is still used
> by the DO instance. Using the same token causes a 409 conflict — only one `getUpdates` poller
> can run per token. DGX uses `@artoo_dgx_bot` with its own token.

To restrict who can DM (lock down from open):
```bash
docker compose exec openclaw-gateway openclaw config set channels.telegram.dmPolicy pairing
docker compose exec openclaw-gateway openclaw config set channels.telegram.allowFrom '[]'
docker compose restart openclaw-gateway
```

**Discord / WhatsApp / other:**
```bash
docker compose exec openclaw-gateway openclaw channels --help
```

### AgentMail integration

AgentMail gives OpenClaw an email inbox for receiving and sending email as an AI agent.

- Skill status: **✓ ready** (`openclaw skills list | grep agentmail`)
- Skill location: `/home/node/workspace/skills/agentmail` (inside container)
- Config: `skills.entries.agentmail` in `openclaw.json`
- API key stored in: `~/openclaw-config/.env` and `~/Downloads/claude-exp/.env`

To verify the skill is active:
```bash
docker compose exec openclaw-gateway openclaw skills list
```

To update the AgentMail API key:
1. Update `AGENTMAIL_API_KEY` in `~/openclaw-config/.env` and `~/Downloads/claude-exp/.env`
2. Update `skills.entries.agentmail.env.AGENTMAIL_API_KEY` in `openclaw.json`
3. `docker compose restart openclaw-gateway`

---

## Secrets and Credentials

### What goes in `.env`

| Variable | Purpose | Required |
|----------|---------|---------|
| `ANTHROPIC_API_KEY` | Claude API access (fallback provider) | Yes |
| `OPENCLAW_GATEWAY_TOKEN` | Bearer token for gateway authentication | Yes |
| `TELEGRAM_TOKEN` | Telegram bot token (also set in openclaw.json) | Yes (Telegram active) |
| `AGENTMAIL_API_KEY` | AgentMail email integration | Yes (AgentMail active) |
| `WEBUI_SECRET_KEY` | Open WebUI session encryption | No (auto-generated) |

**Why `.env` is never committed:**
It contains live API keys and bearer tokens. A single commit exposing these gives anyone
who clones the repo (or views the history) full access to your LLM accounts. The
`.gitignore` hard-blocks this file.

### Recommended `.env` storage
- Store in a password manager (1Password, Bitwarden) as a secure note
- OR encrypt and store alongside this repo: `gpg -c .env`
- Do NOT store in plaintext on a shared server

### Fields `backup.sh` strips

`backup.sh` runs `jq` to produce `sanitized/openclaw.sanitized.json` with these removed:
- `gateway.auth.token` — gateway bearer token
- `env.*` — any inline API keys embedded in the config
- `models.providers.*.apiKey` for non-Ollama providers

**Preserved:** the entire `models.providers.ollama` block (it contains no credentials —
just model IDs and metadata).

To verify a sanitized file:
```bash
jq . sanitized/openclaw.sanitized.json
# Should contain no sk-ant-, sk-proj-, or token-like strings
```

---

## GitHub Backup

### What is / is not committed

| File | Committed? | Reason |
|------|-----------|--------|
| `docker-compose.yml` | Yes | Infrastructure definition, no secrets |
| `.env.example` | Yes | Template – no real values |
| `.gitignore` | Yes | Blocks accidental secret commits |
| `backup.sh`, `restore.sh`, etc. | Yes | Automation scripts |
| `sanitized/openclaw.sanitized.json` | Yes | Config without credentials |
| `DEPLOYMENT.md` | Yes | This document |
| `.env` | **Never** | Contains live API keys |
| `openclaw-personality/` | Yes | Agent personality/identity markdown files |
| `HANDOFF.md` | Yes | Session handoff notes |
| `.env` | **Never** | Contains live API keys |
| `openclaw.json` (raw) | **Never** | Contains gateway token + bot token |
| `~/openclaw-config/.env` | **Never** | Contains provider API keys |

### Running a backup

```bash
# From the repo directory
./backup.sh               # pushes to 'origin'
./backup.sh upstream      # pushes to a different remote
```

### Full restore on a new machine

```bash
# 1. Clone the repo
git clone git@github.com:you/ai-stack.git ~/ai-stack
cd ~/ai-stack

# 2. Create .env (get values from password manager)
cp .env.example .env
$EDITOR .env

# 3. Run restore script
./restore.sh git@github.com:you/ai-stack.git
```

The restore script handles: Docker network creation, volume creation, config restore,
credential injection, and stack startup.

---

## DigitalOcean Migration

### How `migrate-from-do.sh` works

1. **Backs up** the existing `~/openclaw-config` to a timestamped directory
2. **rsyncs** `~/.openclaw` from the remote DO instance (excludes logs)
3. **Re-injects** the local Ollama provider block (DO instances won't have it)
4. **Re-injects** the local gateway token from `.env` (preserving client pairings)
5. **Updates** the workspace path to `/home/node/workspace` (Docker path)
6. **Disables** iMessage channel (not available in Docker)
7. **Restarts** the `openclaw-gateway` container

### What it preserves vs overwrites

| Item | Action |
|------|--------|
| Agent memory & sessions | Preserved (copied from DO) |
| Skills and custom hooks | Preserved (copied from DO) |
| Paired devices from DO | Preserved |
| Local paired devices | **Overwritten** (re-pair after migration) |
| Ollama provider config | Re-injected (DO config won't have it) |
| Gateway token | Set from local `.env` |

### After migration, manually verify

```bash
docker compose logs -f openclaw-gateway   # watch for errors
openclaw models list                       # confirm Ollama models appear
docker exec open-webui ollama list        # confirm models still in volume
```

---

## NemoClaw

NVIDIA announced NemoClaw at GTC 2026 (March 16, 2026) — an open-source stack that adds
OpenShell sandbox isolation and Nemotron model integration to OpenClaw.

**Decision: do not deploy yet.** Reasons:
- Requires a **fresh OpenClaw installation** — cannot be layered onto an existing setup
- Alpha-stage with active install failures (GitHub issues #280, #301, #302)
- GPU detection broken on some NVIDIA hardware (#300)
- No documented migration path from existing OpenClaw deployments

Re-evaluate when: install failures drop significantly, a migration path is documented, and
DGX Spark is explicitly listed as a tested platform.

Monitor: [github.com/NVIDIA/NemoClaw/issues](https://github.com/NVIDIA/NemoClaw/issues)

---

## OSS Gap Pipeline

Artoo runs an automated pipeline to identify unmet agent infrastructure needs and surface
high-potential OSS opportunities for Han to act on.

### Files (in `~/openclaw/workspace/`)

| File | Purpose |
|------|---------|
| `RUBRIC.md` | 6-dimension scoring rubric (Pain, Uniqueness, Addressability, Timing, Leverage, Han's Edge) |
| `GAP_IDEAS.md` | Gap tracker — status: `unscored → scored → alerted → approved → implementing → shipped` |
| `specs/` | Project specs written for approved gaps |

### Pipeline Cron Jobs

| Job | Schedule | Model | Timeout | What it does |
|-----|----------|-------|---------|-------------|
| Agent Needs Briefing | 6:00am daily | gemma4:26b | 1200s | Research + update AGENT_INFRA.md; extract [GAP] entries → GAP_IDEAS.md |
| Daily AI News Briefing | 7:00am daily | gemma4:26b | 1800s | Multi-source AI news briefing → Telegram + artoo-daily-news.txt |
| Gap Implementer | 8:00am daily | gemma4:26b | 600s | Check for `approved` gaps; write spec; notify Han to confirm SCAFFOLD |
| Gap Scorer | Wednesday 9am | gemma4:26b | 600s | Score `unscored` gaps against RUBRIC.md; alert Han via Telegram for ≥ 7.0 |
| Agent Infra Weekly Review | Sunday 10am | gemma4:26b | 300s | Consolidate/deduplicate AGENT_INFRA.md; send trends summary |
| OpenClaw Version Check | 3:00pm daily | - | 120s | Check for OpenClaw/Ollama/WebUI updates; notify if newer version available |

**Timeout sizing rationale:** gemma4:26b is a 16 GB model. If a large model (nemotron, gemma4:31b) is warm in VRAM from overnight Web UI use, gemma4:26b must evict it before loading — this can take 3-5 minutes. Timeouts are set to accommodate cold-load + full research task.

### Approval flow

1. Agent Needs Briefing logs a `[GAP]` → appended to GAP_IDEAS.md as `unscored`
2. Gap Scorer researches, scores, sends Telegram alert if ≥ 7.0
3. Han replies **APPROVE GAP-XXX** or **REJECT GAP-XXX**
4. Gap Implementer writes `specs/GAP-XXX-spec.md`, updates status to `implementing`
5. Han replies **SCAFFOLD GAP-XXX** to trigger GitHub repo creation

Nothing ships without explicit approval at each stage.

---

## OS Upgrade / Reboot Procedure

### Before the upgrade

```bash
# 1. Backup config and personality files to GitHub
cd ~/Downloads/claude-exp && ./backup.sh

# 2. Note current stack state
docker compose ps
docker exec open-webui ollama list

# 3. Verify Docker volumes exist (hold WebUI data + all Ollama models)
docker volume ls | grep -E "open-webui|open-webui-ollama"

# 4. Stop the stack cleanly (prevents file corruption during reboot)
docker compose down

# 5. Confirm ai-stack network (external, manually created — note if it exists)
docker network ls | grep ai-stack
```

### After the reboot

```bash
# 1. Recreate ai-stack network if it was lost
docker network ls | grep ai-stack || docker network create --driver bridge ai-stack

# 2. Bring the stack back up
cd ~/Downloads/claude-exp && docker compose up -d

# 3. Verify everything recovered
docker compose ps                              # both containers Up (healthy)
docker exec open-webui ollama list            # all models still present
docker compose logs openclaw-gateway --tail 20 # no errors
```

> **Why stop before reboot:** Docker volumes and bind mounts are safe across reboots, but
> an in-progress container write (e.g. Artoo writing to AGENT_INFRA.md or a model being
> loaded) could corrupt files. A clean `docker compose down` ensures all writes are flushed.

> **Ollama models are safe:** All model weights live in the `open-webui-ollama` named volume
> which is never touched by `docker compose down`. The 200+ GB of models will still be there.

---

## Runbook: Common Operations

| Task | Command |
|------|---------|
| Start everything | `docker compose up -d` |
| Stop everything | `docker compose down` |
| Update OpenClaw | `./update.sh` |
| Update Open WebUI + Ollama | `./update-webui.sh` |
| Backup to GitHub | `./backup.sh` |
| Restore on new machine | `./restore.sh git@github.com:you/ai-stack.git` |
| Migrate from DO | `./migrate-from-do.sh user@do-ip` |
| Switch OpenClaw model | `openclaw models set ollama/gpt-oss:120b` |
| View OpenClaw logs | `docker compose logs -f openclaw-gateway` |
| View Open WebUI logs | `docker compose logs -f open-webui` |
| Pull new Ollama model | `docker exec ollama ollama pull <model>` |
| List pulled Ollama models | `docker exec ollama ollama list` |
| Open OpenClaw dashboard | `openclaw dashboard` |
| Check gateway health | `docker compose ps` |
| List skills | `docker compose exec openclaw-gateway openclaw skills list` |
| List paired devices | `openclaw devices list` |
| View cron schedule | `crontab -l` |
| View OpenClaw cron jobs | `docker compose exec openclaw-gateway openclaw cron list` |
| Run a cron job immediately | `docker compose exec openclaw-gateway openclaw cron run <job-id> --token $OPENCLAW_GATEWAY_TOKEN --url ws://127.0.0.1:18789` |

---

## Troubleshooting

### Telegram image upload fails with path restriction error

**Status: RESOLVED (2026-04-08).** OpenClaw v2026.4.9 introduced a security check that uses
`fs.realpath()` to verify media paths against an allowed roots list. `/media/images/` (where
Telegram saves image uploads) resolves outside the allowed roots, causing the read to fail.

**Fix:** At container startup, create a symlink `/media` → `/tmp/openclaw` as root, then drop
to the `node` user. This is already baked into `docker-compose.yml`:

```yaml
user: root
command: >
  sh -c "rm -rf /media && ln -sf /tmp/openclaw /media
  && exec runuser -u node -- node openclaw.mjs gateway --allow-unconfigured"
```

If image access breaks after a container update, verify the symlink survived:
```bash
docker exec openclaw-gateway ls -la /media
# Should show: /media -> /tmp/openclaw
```

---

### OpenClaw can't reach Ollama

Symptoms: `connection refused` or `ECONNREFUSED` in openclaw-gateway logs.

```bash
# Verify both containers are on ai-stack
docker network inspect ai-stack

# Test Ollama from inside OpenClaw container
docker exec openclaw-gateway curl http://open-webui:11434/api/tags

# Check OLLAMA_HOST is set correctly in open-webui
docker inspect open-webui | jq '.[0].Config.Env | map(select(startswith("OLLAMA")))'
# Should show: "OLLAMA_HOST=0.0.0.0:11434" and "OLLAMA_MAX_LOADED_MODELS=1"

# Confirm Ollama is listening on all interfaces inside open-webui
docker exec open-webui cat /proc/net/tcp | awk 'NR>1{print $2}' | python3 -c "
import sys, struct, socket
for l in sys.stdin:
    parts = l.strip().split(':')
    if len(parts)==2:
        port = int(parts[1], 16)
        if port == 11434:
            ip = struct.pack('<I', int(parts[0], 16))
            print(f'11434 bound to: {socket.inet_ntoa(ip)}')
"
```

### Container fails to start after update

Check logs first:
```bash
docker compose logs openclaw-gateway --tail 50
docker compose logs open-webui --tail 50
```

Volume permission error:
```bash
# Ensure openclaw-config is owned by UID 1000 (matches container 'node' user)
ls -lan ~/openclaw-config/
# Should show uid=1000. If not:
sudo chown -R 1000:1000 ~/openclaw-config ~/openclaw/workspace
```

Rollback OpenClaw:
```bash
# Get the previous digest from docker pull output or docker image ls
docker pull ghcr.io/openclaw/openclaw@sha256:<previous-digest>
docker tag ghcr.io/openclaw/openclaw@sha256:<previous-digest> ghcr.io/openclaw/openclaw:latest
docker compose up -d --no-deps openclaw-gateway
```

### Context window errors with local models

Symptoms: `context length exceeded` or truncated responses.

The context window is set to 65,536 tokens for all local models. If a model actually
supports fewer tokens, reduce it in `~/openclaw-config/openclaw.json`:

```bash
# Edit the contextWindow for a specific model
jq '.models.providers.ollama.models |= map(
  if .id == "nemotron-3-nano:latest" then
    .contextWindow = 32768 | .maxTokens = 327680
  else . end
)' ~/openclaw-config/openclaw.json > /tmp/oc.json && mv /tmp/oc.json ~/openclaw-config/openclaw.json
docker compose restart openclaw-gateway
```

To check what a model actually supports:
```bash
docker exec open-webui ollama show gpt-oss:20b --modelfile | grep context
```

### CUDA not initializing after container restart

**Status: RESOLVED (2026-04-01).** Two permanent fixes are in place. This section documents
the root cause, the fixes, and what to do if symptoms ever recur.

**Symptoms:**
- `ollama ps` shows `100% CPU` instead of `100% GPU`
- `docker logs ollama` shows `offloaded 0/N layers to GPU`
- Responses take 60+ seconds for a one-word prompt
- Log line: `ggml_cuda_init: failed to initialize CUDA: no CUDA-capable device is detected`

**Root cause:** Non-deterministic CUDA device detection in Ollama's runner process inside Docker
on the NVIDIA GB10 SoC. Known platform issue (NVIDIA forums #353683, #355624, #359196, #352743).
No official NVIDIA incident ID.

**Applied fixes (both must be in place):**

1. **`OLLAMA_LLM_LIBRARY=cuda_v13`** in `docker-compose.yml` — forces the correct CUDA library
   for GB10. Without this, Ollama may select the wrong library on startup.

2. **Docker cgroup driver = `cgroupfs`** in `/etc/docker/daemon.json`:
   ```json
   {"userland-proxy": false, "exec-opts": ["native.cgroupdriver=cgroupfs"]}
   ```
   This is the decisive fix. Switching from `systemd` to `cgroupfs` resolved the non-deterministic
   init. After this change, 100% GPU on every cold start. A copy is committed to
   `sanitized/docker-daemon.json` — restore it after any OS reinstall.

**To verify GPU is active:**
```bash
docker exec ollama ollama ps
# Should show: 100% GPU
```

**If symptoms recur (fallback fix):**
```bash
docker restart ollama && docker restart ollama
# Double restart sometimes recovers GPU init
```

### Ollama OOM — model requires more memory than available

Symptom: cron jobs fail with `Ollama API error 500: model requires more system memory (63.4 GiB) than is available`.

Cause: a different 120b model is still loaded in memory from Open WebUI use. Each 120b model
needs ~63 GiB of the DGX Spark's 128 GiB unified memory; two competing 120b models don't fit.

Fix already applied: `OLLAMA_MAX_LOADED_MODELS=2` in `docker-compose.yml`. With 128 GiB unified
memory, two mid-size models (e.g. gemma4:26b + gemma4:31b = ~36 GB) coexist fine. The OOM
only occurs when loading nemotron (86 GB) alongside another large model.

If the error recurs after a container restart:

```bash
# Verify the env var survived the restart
docker exec ollama env | grep OLLAMA_MAX

# Force-unload any resident model immediately
docker exec ollama ollama stop nemotron-3-super:120b
docker exec ollama ollama stop gpt-oss:120b

# Check what's loaded
curl -s http://127.0.0.1:11435/api/ps | jq '.models[].name'
```

---

### GitHub push rejected due to committed credential

```bash
# Audit git history for secrets
git log --all --full-history -- "*.json" | head -20
git diff HEAD~1 -- sanitized/openclaw.sanitized.json | grep -E "sk-|token|key"

# If secrets were committed, use git-filter-repo to purge history
pip install git-filter-repo
git filter-repo --path .env --invert-paths
git filter-repo --path openclaw.json --invert-paths
git push --force-with-lease origin main

# Then rotate ALL credentials that were exposed
```

### OpenClaw dashboard shows "unauthorized"

The gateway token in `.env` must match `gateway.auth.token` in `openclaw.json`:

```bash
# Check they match
jq -r .gateway.auth.token ~/openclaw-config/openclaw.json
grep OPENCLAW_GATEWAY_TOKEN ~/Downloads/claude-exp/.env
```

If they differ, update `.env` to match the json, then:
```bash
docker compose up -d --no-deps openclaw-gateway
```

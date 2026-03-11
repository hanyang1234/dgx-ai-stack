# AI Stack Deployment — NVIDIA DGX Spark

> **Living document** — run `./backup.sh` after any stack change to keep this in sync with GitHub.

---

## Stack Overview

```
HOST: NVIDIA DGX Spark (Ubuntu)
│
│  Native processes (host, NOT Docker):
│  ├── ollama serve          :11434  (native Ollama – has 2 of 4 models)
│  └── (openclaw-gateway disabled – Docker manages it now)
│
│  Docker network: ai-stack (bridge)
│  │
│  ├── open-webui  (ghcr.io/open-webui/open-webui:ollama)
│  │   ├── Open WebUI         0.0.0.0:12000 → :8080     (public on this host)
│  │   ├── Ollama API         127.0.0.1:11435 → :11434  (localhost-only)
│  │   ├── Volume: open-webui            → /app/backend/data
│  │   └── Volume: open-webui-ollama     → /root/.ollama
│  │
│  └── openclaw-gateway  (ghcr.io/openclaw/openclaw:latest, v2026.3.8)
│      ├── Gateway            127.0.0.1:18789 → :18789  (localhost-only)
│      ├── Bind: ~/openclaw-config        → /home/node/.openclaw
│      └── Bind: ~/openclaw/workspace     → /home/node/workspace
│
│  Internal traffic (ai-stack, never leaves Docker):
│      openclaw-gateway → open-webui:11434  (Ollama API, native format)
```

### Port Map

| Port | Bind | Service | Visible to |
|------|------|---------|------------|
| `12000` | `0.0.0.0` | Open WebUI | Public on host |
| `11434` | `0.0.0.0` | **Native** Ollama (host process) | Public on host |
| `11435` | `127.0.0.1` | Container Ollama (inside open-webui) | Localhost only |
| `18789` | `127.0.0.1` | OpenClaw gateway | Localhost only |

> **Port 11434 note:** The host's native Ollama daemon occupies `0.0.0.0:11434`.
> The bundled Ollama inside the open-webui container is accessible from other containers via
> `http://open-webui:11434` (internal Docker network), and from the host at `127.0.0.1:11435`.

---

## Ollama / Open WebUI

**Based on:** [NVIDIA DGX Spark playbook](https://build.nvidia.com/spark/open-webui)

**Why the bundled image:** The `ghcr.io/open-webui/open-webui:ollama` image bundles Ollama and
Open WebUI in a single container, which is the recommended approach for the DGX Spark. Ollama
runs as a subprocess managed by the Open WebUI startup script. This means:
- Ollama does not have a separate container or image to manage.
- Models downloaded via the WebUI are stored in the `open-webui-ollama` volume.
- Ollama is accessible from other Docker containers at `http://open-webui:11434`.
- The `OLLAMA_HOST=0.0.0.0:11434` env var is required to make Ollama bind to all interfaces
  inside the container (default is loopback-only), enabling cross-container access.

### Named Volumes

| Volume | Container Path | Contents |
|--------|---------------|---------|
| `open-webui` | `/app/backend/data` | WebUI SQLite database, user settings, uploaded files |
| `open-webui-ollama` | `/root/.ollama` | All downloaded Ollama model weights |

### Pulling new Ollama models

**Via Open WebUI (recommended):**
1. Open `http://localhost:12000`
2. Admin → Models → Pull from Ollama.com

**Via CLI:**
```bash
docker exec open-webui ollama pull llama3.3
docker exec open-webui ollama list
```

### Updating Open WebUI without losing models

```bash
./update-webui.sh
```
This pulls the latest image, recreates the container, and verifies all models are intact.
The volumes (`open-webui`, `open-webui-ollama`) are never deleted by this script.

---

## OpenClaw

### Image version
Pinned to `ghcr.io/openclaw/openclaw:latest` which resolves to **v2026.3.8** at time of
deployment. This is the minimum version required to avoid **CVE-2026-25253** (remote code
execution via malformed provider response in versions < 2026.1.29).

To update:
```bash
./update.sh
```

### How Ollama models are wired in

OpenClaw connects to the Ollama inside `open-webui` via the internal `ai-stack` Docker network.
The provider block in `~/openclaw-config/openclaw.json`:

```json5
{
  models: {
    providers: {
      ollama: {
        baseUrl: "http://open-webui:11434",   // internal Docker hostname
        apiKey: "ollama-local",               // any value – Ollama ignores it
        api: "ollama",                        // uses native /api/chat (full tool support)
        models: [...]
      }
    }
  }
}
```

**Why native API (`api: "ollama"`) instead of OpenAI-compat?**
The native Ollama API (`/api/chat`) fully supports streaming + tool calling simultaneously.
The OpenAI-compatible endpoint (`/v1/chat/completions`) may not support both at once.

### Configured Ollama models

| OpenClaw model ID | Name | Size | Role |
|---|---|---|---|
| `ollama/gpt-oss:120b` | GPT-OSS 120B | 65 GB | Large reasoning |
| `ollama/gpt-oss:20b` | GPT-OSS 20B Fast | 13 GB | Subagents / fast |
| `ollama/qwen3-coder:latest` | Qwen3-Coder | 18 GB | Coding tasks |
| `ollama/nemotron-3-nano:latest` | Nemotron-3 Nano — Thinking Mode | 24 GB | **Primary** — reasoning/thinking |

Context window: **65,536 tokens** for most local models; **131,072 tokens** for Nemotron-3 (thinking mode).

### Primary model

**Nemotron-3 Nano in thinking mode** (`ollama/nemotron-3-nano:latest`) is the primary model.
Fallbacks (in order): `anthropic/claude-opus-4-6` → `anthropic/claude-sonnet-4-6` → `openai/gpt-5.1-codex`.

Nemotron is configured with `reasoning: true` and `params: {thinking: true, streaming: false}`,
giving it chain-of-thought reasoning before producing its final answer. Context window: 128k tokens.

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

**Telegram** — already configured and running as `@hanopenclaw123bot`:
- Bot token is set in `openclaw.json` under `channels.telegram.botToken`
- Plugin is enabled under `plugins.entries.telegram.enabled: true`
- DM policy: `pairing` (users must be paired before chatting)
- Group policy: `allowlist` (add group IDs to `channels.telegram.groupAllowFrom` to enable)

To re-pair or add a new device via Telegram: message the bot `/pair` from Telegram.

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
| `openclaw.json` (raw) | **Never** | Contains gateway token |
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
| Pull new Ollama model | `docker exec open-webui ollama pull <model>` |
| List pulled Ollama models | `docker exec open-webui ollama list` |
| Open OpenClaw dashboard | `openclaw dashboard` |
| Check gateway health | `docker compose ps` |
| List skills | `docker compose exec openclaw-gateway openclaw skills list` |
| List paired devices | `openclaw devices list` |
| View cron schedule | `crontab -l` |

---

## Troubleshooting

### OpenClaw can't reach Ollama

Symptoms: `connection refused` or `ECONNREFUSED` in openclaw-gateway logs.

```bash
# Verify both containers are on ai-stack
docker network inspect ai-stack

# Test Ollama from inside OpenClaw container
docker exec openclaw-gateway curl http://open-webui:11434/api/tags

# Check OLLAMA_HOST is set correctly in open-webui
docker inspect open-webui | jq '.[0].Config.Env | map(select(startswith("OLLAMA")))'
# Should show: "OLLAMA_HOST=0.0.0.0:11434"

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

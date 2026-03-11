# Handoff — AI Stack on DGX Spark

**Date:** 2026-03-09
**Session:** Initial deployment — OpenClaw + Open WebUI Dockerization
**Status:** Stack running, one manual step remaining

---

## What Was Done This Session

1. **Upgraded Open WebUI** — pulled the latest `ghcr.io/open-webui/open-webui:ollama` image, recreated the container with two additions: `OLLAMA_HOST=0.0.0.0:11434` (so other containers can reach the bundled Ollama) and membership in a new `ai-stack` bridge network.

2. **Deployed OpenClaw in Docker** — pulled `ghcr.io/openclaw/openclaw:latest` (v2026.3.8, safe from CVE-2026-25253), configured it with the existing native-install config, and started it as `openclaw-gateway`.

3. **Migrated native OpenClaw to Docker** — the old native OpenClaw (v2026.2.15) was running as a user systemd service. It was stopped, disabled, and its config (`~/.openclaw/`) was copied to `~/openclaw-config/` which is now the Docker bind mount. All existing agent sessions, paired devices (openclaw-tui), and the gateway token were preserved.

4. **Wired Ollama into OpenClaw** — added an explicit Ollama provider block to `~/openclaw-config/openclaw.json` pointing at `http://open-webui:11434` (internal Docker network). All 4 pulled models are pre-configured with 65k context windows.

5. **Reset Open WebUI password** — account `han.yang123@yahoo.com` (admin) was reset to `changeme123`. Change it after next login.

6. **Created all repo files** — see Files section below.

---

## Current Stack State

```
CONTAINER           STATUS          PORTS
open-webui          Up (healthy)    0.0.0.0:12000→8080, 127.0.0.1:11435→11434
openclaw-gateway    Up (healthy)    127.0.0.1:18789→18789
```

Both containers have `restart: unless-stopped` — they will come back automatically after a reboot.

### Ollama Models (in open-webui container)

| Model | Size | Role in OpenClaw |
|-------|------|-----------------|
| `gpt-oss:120b` | 65 GB | Large reasoning (`ollama/gpt-oss:120b`) |
| `gpt-oss:20b` | 13 GB | Fast / subagents (`ollama/gpt-oss:20b`) |
| `qwen3-coder:latest` | 18 GB | Coding (`ollama/qwen3-coder:latest`) |
| `nemotron-3-nano:latest` | 24 GB | Light/fast (`ollama/nemotron-3-nano:latest`) |

### OpenClaw Primary Model
`anthropic/claude-opus-4-6` — **will not work until ANTHROPIC_API_KEY is added** (see below).

---

## One Remaining Manual Step

**Add your Anthropic API key:**

```bash
nano ~/Downloads/claude-exp/.env
# Set: ANTHROPIC_API_KEY=sk-ant-...
```

Then apply it:
```bash
cd ~/Downloads/claude-exp
docker compose restart openclaw-gateway
```

Verify:
```bash
openclaw models list   # should show anthropic/claude-opus-4-6 as authenticated
```

Until this is done, OpenClaw will fall back to `openai/gpt-5.1-codex` (OPENAI_API_KEY is already configured in `~/openclaw-config/.env` from the native install).

---

## Key File Locations

| Path | What it is |
|------|-----------|
| `~/Downloads/claude-exp/` | Repo root — all scripts and compose file live here |
| `~/Downloads/claude-exp/.env` | **Secrets** (gitignored) — add ANTHROPIC_API_KEY here |
| `~/Downloads/claude-exp/docker-compose.yml` | Canonical stack definition |
| `~/openclaw-config/` | OpenClaw config bind-mount (host-side view of `/home/node/.openclaw`) |
| `~/openclaw-config/openclaw.json` | Main OpenClaw config — models, gateway, hooks |
| `~/openclaw-config/.env` | OpenClaw's own env file — has OPENAI_API_KEY |
| `~/openclaw/workspace/` | Agent working directory (bind-mounted into container) |

---

## Ports at a Glance

| Port | Bind | What |
|------|------|------|
| `12000` | `0.0.0.0` | Open WebUI (public) |
| `11434` | `0.0.0.0` | **Native** host Ollama (separate process, 2 models) |
| `11435` | `127.0.0.1` | Container Ollama inside open-webui (4 models) |
| `18789` | `127.0.0.1` | OpenClaw gateway |

---

## Quirks to Know

- **Port 11434 conflict** — the host has a native `ollama serve` process (systemd, pid varies) that holds `0.0.0.0:11434`. The container's Ollama is on `11435` on the host side but reachable internally at `http://open-webui:11434`. Don't stop the native Ollama unless you know what depends on it.

- **Native OpenClaw is disabled** — `~/.config/systemd/user/openclaw-gateway.service` still exists but is disabled. Do not re-enable it; it would conflict with Docker on port 18789. To permanently remove it: `openclaw uninstall --keep-cli`.

- **iMessage disabled** — the Docker container has no `imsg` binary, so the iMessage channel is set to `enabled: false` in `openclaw.json`. The native install had it enabled (though it was failing to connect anyway).

- **OLLAMA_HOST env var is required** — without `OLLAMA_HOST=0.0.0.0:11434` in the open-webui container, Ollama binds to loopback only and OpenClaw cannot reach it. This is set in `docker-compose.yml` and must not be removed.

---

## Where to Pick Up Next

To resume in a new Claude Code session:

```bash
cd ~/Downloads/claude-exp
# Start Claude Code here — it will read DEPLOYMENT.md and handoff.md for context
```

Suggested next tasks:
- Add `ANTHROPIC_API_KEY` to `.env` and verify Claude works
- Set up a GitHub remote and run `./backup.sh`
- Configure Telegram if desired: `docker compose exec openclaw-gateway openclaw channels add --channel telegram --token $TOKEN`
- Pair a new client device if needed: `openclaw devices list`

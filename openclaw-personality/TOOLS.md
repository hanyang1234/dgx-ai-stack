# TOOLS.md - Local Notes

Skills define _how_ tools work. This file is for _your_ specifics — the stuff that's unique to your setup.

## What Goes Here

Things like:

- Camera names and locations
- SSH hosts and aliases
- Preferred voices for TTS
- Speaker/room names
- Device nicknames
- Anything environment-specific

## Examples

```markdown
### Cameras

- living-room → Main area, 180° wide angle
- front-door → Entrance, motion-triggered

### SSH

- home-server → 192.168.1.100, user: admin

### TTS

- Preferred voice: "Nova" (warm, slightly British)
- Default speaker: Kitchen HomePod
```

## Why Separate?

Skills are shared. Your setup is yours. Keeping them apart means you can update skills without losing your notes, and share skills without leaking your infrastructure.

---

## Current Default Model

**Your default model is `ollama/gemma4:26b`** (updated 2026-04-08).

Do NOT say your default is qwen3.5:9b — that is outdated. If asked what model you are running, say gemma4:26b.

---

## Cron Jobs

When Solo asks you to create or edit a cron job, **always ask which model to use** before finalizing the job. Cron jobs are batch tasks that run unattended — model choice matters:

- **Fast/simple tasks** (file writes, lookups): `ollama/qwen3.5:9b`
- **Research/briefing tasks**: `ollama/gemma4:26b` (default)
- **Deep reasoning tasks**: `ollama/qwen3.5:122b-a10b-q4_K_M` or `ollama/nemotron-cascade-2:latest`
- **Frontier quality** (if Anthropic credits available): `anthropic/claude-haiku-4-5` (cheap) or `anthropic/claude-sonnet-4-6`

If Solo doesn't specify, prompt: *"Which model should this cron job use? (default: gemma4:26b)"*

---

## LLM Wiki

You maintain a persistent AI knowledge wiki at `/home/node/workspace/wiki/`.

- **`wiki/index.md`** — catalog of all topic pages (always read this first)
- **`wiki/log.md`** — append-only ingest history
- **`wiki/<topic>.md`** — one page per topic (e.g., `reasoning-models.md`, `openai.md`, `hardware.md`)

**When to use the wiki:**
- At the start of the Daily AI News Briefing: read `index.md` + relevant pages for historical context
- When Solo asks a question about AI developments: read relevant wiki pages before answering
- After the daily briefing: ingest today's stories back into the wiki

**Answering wiki queries from Solo:**
Read `wiki/index.md` first → read relevant topic page(s) → synthesize answer with dates and citations.

---

## System Versions

You cannot run shell commands on the host, so you cannot check system versions directly.
Instead, read `/home/node/workspace/tmp/system-snapshot.txt` — this file is written daily
at 5:45am by a host cron job and contains current versions of:

- **DGX OS** — installed OTA version + latest available (with ⚠️ if an update exists)
- **NVIDIA Driver**
- **CUDA**
- **Kernel**
- **Docker**
- **Ollama** (container)
- **OpenClaw** (container)

When Solo asks about system versions or "is there a new DGX OS", read this file first.
Do NOT attempt to use the browser or exec tools to check versions — read the snapshot file.

---

Add whatever helps you do your job. This is your cheat sheet.

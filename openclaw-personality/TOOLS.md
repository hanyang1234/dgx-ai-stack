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

Add whatever helps you do your job. This is your cheat sheet.

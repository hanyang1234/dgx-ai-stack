# Claude Code ↔ Artoo Architecture

**Status:** Proposal — not yet implemented beyond Directions 1–3
**Last updated:** 2026-04-14

---

## Overview

Two AI agents share the same DGX Spark host. They have complementary strengths and
complementary weaknesses. This document describes the interface between them — what each can do
to the other, how information flows, and a proposed future extension (Direction 4) that would
allow the two agents to hand work back and forth without human involvement.

---

## Component Architecture

```
┌──────────────────────────────────────────────────────────────────────────────┐
│  NVIDIA DGX Spark GB10 (128 GiB unified memory)                              │
│                                                                              │
│  ┌──────────────────────────────────────────────────────────────────────┐   │
│  │  Docker network: ai-stack                                            │   │
│  │                                                                      │   │
│  │  ┌───────────────────────┐   ┌────────────────────────────────────┐ │   │
│  │  │  ollama               │   │  openclaw-gateway                  │ │   │
│  │  │  (v0.20.5+)           │◄──│  (2026.4.12)                       │ │   │
│  │  │                       │   │                                    │ │   │
│  │  │  gemma4:26b (default) │   │  Agent: Artoo (@artoo_dgx_bot)    │ │   │
│  │  │  gemma4:31b           │   │  Cron jobs (6 active)              │ │   │
│  │  │  qwen3.5:9b           │   │  Wiki: ~/openclaw/workspace/wiki/  │ │   │
│  │  │  qwen3.5:122b         │   │  Workspace: ~/openclaw/workspace/  │ │   │
│  │  │  nemotron-cascade-2   │   │                                    │ │   │
│  │  │  ... (11 models)      │   │  Channels: Telegram (Han, chatId   │ │   │
│  │  └───────────────────────┘   │  8128617103), AgentMail            │ │   │
│  │                              └────────────────────────────────────┘ │   │
│  │  ┌───────────────────────┐                                          │   │
│  │  │  open-webui           │   Artoo config:                          │   │
│  │  │  (Open WebUI latest)  │   ~/openclaw-config/ → /home/node/.openclaw│ │
│  │  │  Port 12000 (LAN)     │                                          │   │
│  │  └───────────────────────┘                                          │   │
│  └──────────────────────────────────────────────────────────────────────┘   │
│                                                                              │
│  ┌──────────────────────────────────────────────────────────────────────┐   │
│  │  Claude Code  (this process)                                         │   │
│  │                                                                      │   │
│  │  Model: claude-sonnet-4-6 (via Anthropic API)                       │   │
│  │  Context: ~/Downloads/claude-exp/ (repo root)                        │   │
│  │  Access: full host filesystem + Docker CLI                           │   │
│  │                                                                      │   │
│  │  ┌──────────────────────────┐  ┌─────────────────────────────────┐ │   │
│  │  │  Shared state (host FS)  │  │  Control interface              │ │   │
│  │  │                          │  │                                 │ │   │
│  │  │  ~/openclaw/workspace/   │  │  docker exec openclaw-gateway   │ │   │
│  │  │    wiki/          ◄──────│──│  openclaw cron run <id>         │ │   │
│  │  │    TOOLS.md              │  │                                 │ │   │
│  │  │    SKILLS.md             │  │  Edit jobs.json directly        │ │   │
│  │  │    GAP_IDEAS.md          │  │  (bound into container)         │ │   │
│  │  │    tmp/                  │  │                                 │ │   │
│  │  │  ~/openclaw-config/      │  │  Gateway API (WS/HTTP)          │ │   │
│  │  │    jobs.json      ◄──────│──│  ws://127.0.0.1:18789           │ │   │
│  │  │    openclaw.json         │  └─────────────────────────────────┘ │   │
│  │  └──────────────────────────┘                                       │   │
│  └──────────────────────────────────────────────────────────────────────┘   │
│                                                                              │
│  Host cron: backup.sh (2am daily), send_daily.sh (5am daily)                │
└──────────────────────────────────────────────────────────────────────────────┘
```

---

## Capability Comparison

| Capability | Claude Code | Artoo |
|---|---|---|
| Model | claude-sonnet-4-6 (frontier) | gemma4:26b (local, 16 tok/s) |
| Context window | ~200K tokens | 262K tokens (but bloat kills it in practice) |
| Code generation | Excellent | Good for scripts |
| Web search | Via tool | Via web search tool |
| Docker/infra access | Full (host shell) | None |
| Persistent memory | Wiki + Claude memory | Wiki + OpenClaw memory |
| Autonomous cron | Via host crontab | Native cron jobs |
| Telegram | None | Yes (@artoo_dgx_bot) |
| Email | None | Yes (AgentMail) |
| File edits | Full read/write | Workspace only (`~/openclaw/workspace/`) |
| Session continuity | Single-session | Persistent across sessions |
| Availability | On-demand (you invoke it) | 24/7 autonomous |

---

## Handoff Flow — Three Directions (Current)

```
                         ┌─────────────────────┐
                         │       Han            │
                         │  (iPhone / Mac)      │
                         └─────────┬───────────┘
                                   │
                    ┌──────────────┴───────────────┐
                    │                              │
              Telegram                         Claude.ai / IDE
                    │                              │
                    ▼                              ▼
         ┌──────────────────┐          ┌───────────────────────┐
         │      Artoo       │          │      Claude Code       │
         │  (always on)     │          │  (on-demand, DGX host) │
         └──────────────────┘          └───────────────────────┘
                   │                              │
      Direction 1  │ ◄────────────────────────────│ Direction 2
      (wiki write)─┘                              │─ (read Artoo outputs)
                                                  │
                                  Direction 3     │
                                  (manage Artoo)──┘

  ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─
  [ PROPOSED ]
                                  Direction 4
                               (Artoo tasks Claude)
         ┌──────────────────┐   writes trigger file   ┌──────────────────┐
         │      Artoo       │ ──────────────────────► │   host cron      │
         │                  │   ~/openclaw/workspace/  │   watches        │
         └──────────────────┘   handoff/task.json     │   handoff/ dir   │
                                                       │   runs claude    │
                                                       └──────────────────┘
  ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─
```

### Direction 1: Claude Code → Wiki (Artoo reads)

Claude Code writes structured knowledge into `~/openclaw/workspace/wiki/`.
Artoo's daily briefing cron jobs read `wiki/index.md` at startup (Phase 0), then pull
relevant pages during research. This is the primary async information channel.

Examples:
- Claude Code ingests a paper/article → writes to a wiki page
- Claude Code updates `wiki/index.md` after adding a new page
- Claude Code fixes wiki pages that are too thin (wiki-enrich job also does this)

**What Artoo sees:** fresh wiki pages the next time a cron job reads them.
**Latency:** next cron run (hours, not seconds).

### Direction 2: Artoo → Files (Claude Code reads)

Artoo writes its briefing output and working files to `~/openclaw/workspace/tmp/`:
- `artoo-daily-news.txt` — Daily AI News Briefing
- `artoo-agent-infra.txt` — Agent Needs Briefing
- `artoo-infra-weekly.txt` — Agent Infra Weekly Review

Claude Code can read these at the start of a session to catch up on what Artoo observed.
Artoo also updates `GAP_IDEAS.md`, `AGENT_INFRA.md`, and the wiki itself — all host-visible.

### Direction 3: Claude Code → Artoo (Claude Code manages Artoo)

Claude Code is the ops layer for Artoo's infrastructure. The control surface:

```bash
# Run a cron job immediately (without waiting for schedule)
source ~/Downloads/claude-exp/.env
docker exec openclaw-gateway node openclaw.mjs cron run <jobId> \
  --token $OPENCLAW_GATEWAY_TOKEN --url ws://127.0.0.1:18789

# Edit cron jobs (bind-mount is live — no restart needed)
# Edit ~/openclaw-config/cron/jobs.json directly

# Edit Artoo's prompt / system context
# Edit ~/openclaw-config/workspace/TOOLS.md
# (also sync ~/openclaw/workspace/TOOLS.md — backup.sh does this)

# Restart the gateway after config changes
docker compose restart openclaw-gateway

# Upgrade OpenClaw version
# Edit docker-compose.yml → image tag → docker compose pull + up
```

**What Artoo cannot do in return:** Artoo has no shell access to the host, cannot exec
outside its workspace sandbox (exec is blocked in isolated sessions), and cannot invoke
Claude Code. Direction 3 is one-way.

---

## The Wiki as Interface Layer

```
   Claude Code                        Artoo
       │                                │
       │  writes structured knowledge   │  reads at cron startup
       ├──────────────────────────────► │  (Phase 0: only index.md)
       │                                │
       │  wiki/index.md                 │  then pulls specific pages
       │  wiki/anthropic.md             │  during research phase
       │  wiki/hardware.md              │  based on relevance to
       │  wiki/quantization.md          │  today's topics
       │  ...10 pages total             │
       │                                │
       │  ◄────────────────────────────── Artoo enriches wiki too:
       │                                │  wiki-enrich cron job
       │                                │  weekly wiki lint job
```

The wiki is the central knowledge substrate. Claude Code (frontier quality, on-demand)
populates and enriches it. Artoo (local, always-on) consumes it and keeps it growing.
Neither needs to be running at the same time for the interface to work.

**Why async beats direct API calls:**
- Artoo's gemma4:26b has limited context — direct injection of research would use it up
- Claude Code sessions end and context is lost — the wiki persists
- Artoo runs cron jobs at 6am when Claude Code is not running

---

## Direction 4 — Proposed: Artoo Tasks Claude Code

**Status: Not yet implemented. Proposal only.**

The asymmetry (Claude Code can invoke Artoo, but not vice versa) limits the system.
Direction 4 would close this loop: Artoo writes a task request to a `handoff/` directory,
and a host cron job watches for it and invokes Claude Code via the CLI.

```
handoff/
  task-20260414-001.json    ← Artoo writes this
  task-20260414-001.done    ← Claude Code writes this when complete
```

### Task file format (proposed)

```json
{
  "id": "task-20260414-001",
  "created": "2026-04-14T06:05:00Z",
  "created_by": "artoo/daily-briefing",
  "priority": "normal",
  "type": "wiki_ingest",
  "description": "Ingest the following URL into the wiki",
  "payload": {
    "url": "https://arxiv.org/abs/2504.01234",
    "target_page": "wiki/quantization.md",
    "notes": "New paper on 2-bit KV cache, follow up to TurboQuant"
  },
  "requires_approval": false
}
```

### Host cron watcher (proposed)

```bash
#!/bin/bash
# /home/hanyang/Downloads/claude-exp/handoff-watcher.sh
# Runs every 15 minutes via crontab
HANDOFF_DIR=~/openclaw/workspace/handoff
for task in "$HANDOFF_DIR"/task-*.json; do
  [[ -f "$task" ]] || continue
  done="${task%.json}.done"
  [[ -f "$done" ]] && continue  # already processed
  claude --print "Process this task: $(cat "$task")" > "${task%.json}.result.txt"
  touch "$done"
done
```

### Why this matters

| Without Direction 4 | With Direction 4 |
|---|---|
| Artoo spots a gap: writes to GAP_IDEAS.md | Same, but also writes handoff/task-xxx.json |
| Han has to notice and ask Claude Code | Claude Code processes automatically (or alerts Han) |
| Frontier research only happens on-demand | Artoo triggers frontier research when needed |
| Briefing quality bounded by gemma4:26b | Artoo can escalate individual questions to Claude |

### Risks and mitigations

| Risk | Mitigation |
|---|---|
| Runaway task creation (Artoo writes thousands of tasks) | Rate-limit: max 3 tasks/day via watcher |
| Costs spiral (each Claude Code invocation = Anthropic API cost) | `requires_approval: true` for expensive tasks |
| Watcher invokes Claude Code during a live session | Check for lock file before running |
| Task format drift | JSON schema validation in watcher |

### Decision: Implement when

1. Artoo's Telegram delivery is stable (currently flaky for long messages)
2. Han has confirmed the wiki ingest workflow is valuable enough to automate
3. The `claude` CLI supports `--print` mode cleanly (verify: `claude --help`)

---

## Known Limitations

- **Artoo cannot reach Claude Code directly** — no API, no shared queue (yet)
- **Context window is the binding constraint** — gemma4:26b's 262K tokens sound large but fill quickly with tool outputs; the Phase 0 fix (read only index.md) is essential
- **Wiki quality depends on Claude Code ingesting** — Artoo's wiki-enrich job helps but frontier-quality enrichment requires a Claude Code session
- **Briefing Telegram delivery sometimes fails for long messages** — Telegram has a 4096-char limit; multi-part delivery not yet implemented
- **Claude Code sessions are ephemeral** — ARCHITECTURE.md, DEPLOYMENT.md, HANDOFF.md, and the auto-memory system (`~/.claude/`) are the only continuity mechanisms

---

## Files That Support This Architecture

| File | Location | Purpose |
|------|----------|---------|
| `TOOLS.md` | `~/openclaw/workspace/` and `~/openclaw-config/workspace/` | Artoo's startup context (both copies must be in sync) |
| `SKILLS.md` | `~/openclaw/workspace/` and `~/openclaw-config/workspace/` | Artoo's skill registry |
| `wiki/index.md` | `~/openclaw/workspace/wiki/` | Wiki table of contents (Phase 0 reads only this) |
| `wiki/*.md` | `~/openclaw/workspace/wiki/` | 10 topic pages |
| `jobs.json` | `~/openclaw-config/cron/` | Artoo's cron job definitions |
| `ARCHITECTURE.md` | `~/Downloads/claude-exp/` | This document |
| `DEPLOYMENT.md` | `~/Downloads/claude-exp/` | Stack operations reference |
| `HANDOFF.md` | `~/Downloads/claude-exp/` | Session handoff notes |
| `.claude/memory/` | `~/.claude/projects/.../memory/` | Claude Code persistent memory |

---

*See DEPLOYMENT.md for operational details. See HANDOFF.md for current stack state.*

# SKILLS.md - Your Capabilities

This is your capability map. Read it at session start so you know what you can do without guessing.

---

## Built-in Tools

### `exec` — Run shell commands
Runs on the **gateway** host (inside the OpenClaw container). Not sandbox.

```
exec: node -e "..."           # Run Node.js inline
exec: cat /path/to/file       # Read files
exec: git add . && git commit # Git operations
```

**Rules:**
- Working directory defaults to `/home/node/workspace`
- Node.js, git, curl, jq all available
- **Known limitation:** Some models (especially local ones) may trigger approval prompts despite gateway config. If exec is blocked, use `fetch` for HTTP tasks and `read`/`write` for file tasks instead.

### `fetch` — HTTP requests
Use for REST APIs and web requests. No exec needed, no approval prompts.

```
fetch: GET https://api.example.com/data
fetch: POST https://api.example.com/endpoint  { "key": "value" }
```

Prefer `fetch` over `exec` for any API call that can be done over HTTP.

### `message` — Send Telegram messages
Send to Solo's Telegram directly.

```
message: action=send, target=8128617103, text="your message"
```

**Never send to targets you weren't given.** Solo's chatId is `8128617103`.

### `read` / `write` — File operations
Access files in your workspace and config.

- Workspace: `/home/node/workspace/`
- Config (read-only): `/home/node/.openclaw/`

### `web_search` — Search the internet
Use for news, research, documentation lookups.

---

## Installed Skills

### AgentMail (`skills/agentmail`)
Your email identity. Send emails on behalf of Artoo.

- **Inbox:** `artooopenclaw@agentmail.to`
- **API key:** `process.env.AGENTMAIL_API_KEY` (set in environment)
- **SDK path:** `/home/node/workspace/skills/agentmail/node_modules/agentmail`

**Send an email via fetch (preferred — no exec needed):**
```
POST https://api.agentmail.to/v0/inboxes/artooopenclaw@agentmail.to/messages
Authorization: Bearer <AGENTMAIL_API_KEY from env>
Content-Type: application/json
{ "to": ["han.yang123@yahoo.com"], "subject": "...", "text": "..." }
```

**Send via Node.js exec (fallback):**
```js
const { AgentMailClient } = require("/home/node/workspace/skills/agentmail/node_modules/agentmail");
const c = new AgentMailClient({ apiKey: process.env.AGENTMAIL_API_KEY });
await c.inboxes.messages.send("artooopenclaw@agentmail.to", {
  to: ["han.yang123@yahoo.com"],
  subject: "Subject here",
  text: "Body here"
});
```

---

## Future Skills

Skills will be added here as Solo installs them. When a new skill is installed, update this section with:
- What it does
- How to invoke it
- Any API keys or paths needed

---

## Models Available (Ollama — local, free)

| Alias | Model ID | Best for |
|---|---|---|
| `local-large` | `ollama/gpt-oss:120b` | Complex reasoning, briefings |
| `local-fast` | `ollama/gpt-oss:20b` | Quick tasks, subagents |
| `local-coder` | `ollama/qwen3-coder:latest` | Code generation |
| `Qwen35` | `ollama/qwen3.5:35b` | General use (default) |
| `Nemotron-Super` | `ollama/nemotron-3-super:120b` | Heavy reasoning |
| `Nemotron-Chat` | `ollama/nemotron-3-nano:latest` | Thinking mode |

Fallbacks (cloud, billed): `Claude` (claude-opus-4-6), `Claude-Fast` (claude-sonnet-4-6), `GPT` (gpt-5.1-codex)

---

## Workspace Layout

```
/home/node/workspace/
├── AGENT_INFRA.md       # Agent infrastructure knowledge base (daily updates)
├── AGENTS.md            # How to operate (read this)
├── SOUL.md              # Who you are
├── USER.md              # Who Solo is
├── TOOLS.md             # Environment-specific tool notes
├── SKILLS.md            # This file
├── RUBRIC.md            # Scoring rubric for OSS gap opportunities
├── GAP_IDEAS.md         # Tracked unmet agent infra needs (OSS pipeline)
├── MEMORY.md            # Long-term memory (main session only)
├── memory/              # Daily session logs (YYYY-MM-DD.md)
├── specs/               # Project specs for approved OSS gaps
└── skills/
    └── agentmail/       # AgentMail SDK + docs
```

---

## Cron Jobs (Scheduled Tasks)

Your scheduled jobs live in `/home/node/.openclaw/cron/jobs.json`. Do **not** create new cron jobs unless Solo explicitly asks.

| Job | Schedule | What it does |
|---|---|---|
| Agent Needs Briefing | 6:00am PT daily | Research agent infra, update AGENT_INFRA.md + GAP_IDEAS.md, brief Solo |
| Daily AI News Briefing | 6:30am PT daily | AI news digest → Telegram |
| OpenClaw Version Check | 3:00pm PT daily | Check for OpenClaw updates |
| Gap Scorer | Wednesday 9am PT | Score unscored gaps in GAP_IDEAS.md, alert Solo for ≥ 7.0 |
| Gap Implementer | 8:00am PT daily | Check for approved gaps, write spec, notify Solo |
| Agent Infra Weekly Review | Sunday 10am PT | Consolidate + review AGENT_INFRA.md |

---

## Key Contacts & IDs

| What | Value |
|---|---|
| Solo's Telegram chatId | `8128617103` |
| Solo's email | `han.yang123@yahoo.com` |
| Artoo's email | `artooopenclaw@agentmail.to` |
| Gateway port | `18789` (localhost only) |

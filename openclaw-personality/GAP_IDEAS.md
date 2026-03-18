# GAP_IDEAS.md - Agent Infrastructure Gap Tracker

This file tracks unmet needs in the agent infrastructure ecosystem.
Gaps are discovered by the Agent Needs Briefing cron job and scored weekly against RUBRIC.md.

---

## How This Works

1. **Artoo** discovers gaps during daily Agent Needs Briefing research and appends entries here with status `unscored`
2. **Gap Scorer** (Wednesday weekly) scores unscored entries, updates status to `scored`, and alerts Solo if score ≥ 7.0
3. **Solo** reviews alerted entries and sets status to `approved` or `rejected`
4. **Gap Implementer** (daily check) picks up `approved` entries, writes spec + scaffolds GitHub repo, sets status to `implementing`

---

## Status Values

| Status | Meaning |
|---|---|
| `unscored` | Discovered, not yet scored |
| `scored` | Scored, below alert threshold (< 7.0) |
| `alerted` | Score ≥ 7.0, Solo notified, awaiting approval |
| `approved` | Solo approved — ready to implement |
| `rejected` | Solo passed on this one |
| `implementing` | Spec written, GitHub repo scaffolded |
| `shipped` | OSS project published |

---

## Gap Entries

---

### GAP-001: Scalable Multi-Agent Coordination Layer

**Discovered:** 2026-03-13
**Status:** unscored
**Source:** Agent Needs Briefing daily research

**Description:**
No vendor-neutral open-source layer exists for dynamic compute allocation, inter-agent messaging, and Quality-of-Service (QoS) guarantees across heterogeneous cloud environments. Current solutions are either cloud-vendor-locked (AWS Step Functions, Azure Durable Functions) or experimental research projects. As multi-agent systems scale to dozens or hundreds of concurrent agents, the lack of a portable coordination substrate forces teams to either adopt vendor lock-in or hand-roll fragile custom solutions.

**Evidence to find:** Look for GitHub issues on LangGraph, CrewAI, AutoGen requesting cross-cloud or heterogeneous scheduling. HN threads on "multi-agent orchestration at scale". Papers citing coordination bottlenecks.

**Scores:** (fill in during weekly scoring)
- Pain Severity: —
- Gap Uniqueness: —
- Addressability: —
- Ecosystem Timing: —
- Leverage: —
- Han's Edge: —
- **Raw total:** —
- **Final score:** —

**Notes:** —

---

### GAP-002: Unified Agent-Economic Marketplace

**Discovered:** 2026-03-13
**Status:** unscored
**Source:** Agent Needs Briefing daily research

**Description:**
No open marketplace exists for agent service publishing, capability discovery, pricing negotiation, and micropayments with reputation scoring. Agents can't find and hire other specialized agents in a standardized, trustworthy way. Current approaches rely on centralized proprietary platforms (OpenAI GPT Store, Anthropic partner integrations) with no open protocol for agent-to-agent economic interaction.

**Evidence to find:** Look for work on agent marketplaces in academic papers (2025–2026), proposals in MCP ecosystem for agent discovery, any open protocols for agent capability advertisement. Check if AGNTCY or similar projects have gained traction.

**Scores:** (fill in during weekly scoring)
- Pain Severity: —
- Gap Uniqueness: —
- Addressability: —
- Ecosystem Timing: —
- Leverage: —
- Han's Edge: —
- **Raw total:** —
- **Final score:** —

**Notes:** —

---

<!-- NEW GAPS APPENDED BELOW BY ARTOO -->

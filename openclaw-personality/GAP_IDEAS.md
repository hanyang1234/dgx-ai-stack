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
**Status:** alerted
**Source:** Agent Needs Briefing daily research

**Description:**
No vendor-neutral open-source layer exists for dynamic compute allocation, inter-agent messaging, and Quality-of-Service (QoS) guarantees across heterogeneous cloud environments. Current solutions are either cloud-vendor-locked (AWS Step Functions, Azure Durable Functions) or experimental research projects. As multi-agent systems scale to dozens or hundreds of concurrent agents, the lack of a portable coordination substrate forces teams to either adopt vendor lock-in or hand-roll fragile custom solutions.

**Evidence to find:** Look for GitHub issues on LangGraph, CrewAI, AutoGen requesting cross-cloud or heterogeneous scheduling. HN threads on "multi-agent orchestration at scale". Papers citing coordination bottlenecks.

**Scores:** (filled)
- Pain Severity: 5/5
- Gap Uniqueness: 4/5
- Addressability: 4/5
- Ecosystem Timing: 4/5
- Leverage: 5/5
- Han's Edge: 4/5
- **Raw total:** 26
- **Final score:** 8.7/10

**Notes:** 
- https://github.com/anthropics/claude-code/issues/28300
- https://github.com/ComposioHQ/agent-orchestrator
- https://www.builder.io/blog/ai-agent-orchestration
- https://dev.to/ggondim/how-i-built-a-deterministic-multi-agent-dev-pipeline-inside-openclaw-and-contributed-a-missing-4ool

---

### GAP-002: Unified Agent-Economic Marketplace

**Discovered:** 2026-03-13
**Status:** alerted
**Source:** Agent Needs Briefing daily research

**Description:**
No open marketplace exists for agent service publishing, capability discovery, pricing negotiation, and micropayments with reputation scoring. Agents can't find and hire other specialized agents in a standardized, trustworthy way. Current approaches rely on centralized proprietary platforms (OpenAI GPT Store, Anthropic partner integrations) with no open protocol for agent-to-agent economic interaction.

**Evidence to find:** Look for work on agent marketplaces in academic papers (2025–2026), proposals in MCP ecosystem for agent discovery, any open protocols for agent capability advertisement. Check if AGNTCY or similar projects have gained traction.

**Scores:** (filled)
- Pain Severity: 4/5
- Gap Uniqueness: 5/5
- Addressability: 3/5
- Ecosystem Timing: 3/5
- Leverage: 5/5
- Han's Edge: 4/5
- **Raw total:** 24
- **Final score:** 8.0/10

**Notes:** 
- https://github.com/microsoft/multi-agent-marketplace
- https://www.microsoft.com/en-us/research/blog/magentic-marketplace-an-open-source-simulation-environment-for-studying-agentic-markets/
- https://arxiv.org/html/2510.25779
- https://gorilla.cs.berkeley.edu/blogs/11_agent_marketplace.html

### GAP-004: Standardized Agent-to-Agent Economic & Reputation Protocol

**Discovered:** 2026-04-17
**Status:** unscored
**Source:** Agent Needs Briefing daily research

**Description:**
While the MCP roadmap focuses on context and tools, there is no standardized, open protocol for agent-to-agent economic negotiation and reputation-based hiring. As multi-agent ecosystems expand (e.g., Google Scion, Microsoft Copilot Studio), agents will need to autonomously discover, evaluate, and pay for specialized services from other agents using standardized capability advertisements and cryptographically verifiable reputation scores to prevent "agent-spam" and ensure service quality.

**Evidence to find:** Look for lack of standardized "agent service level agreements" (SLAs) in current frameworks. Check for absence of verifiable reputation layers in MCP or AutoGen.

**Notes:**
- 


**Discovered:** 2026-04-16
**Status:** unscored
**Source:** Agent Needs Briefing daily research

**Description:**
As agents move from single-turn task completion to long-running, multi-step workflows, there is a critical lack of standardized, "black-box" observability tools capable of auditing the decision-making trace (reasoning chains, tool use, and intermediate state changes) for governance compliance. While basic logging exists, there is no unified protocol for capturing a "forensic trace" of agentic intent and outcome that is verifiable by third-party governance systems without compromising the privacy of the underlying data or the model weights.

**Evidence to find:** Check for discussions on "agentic forensics," "traceable LLM workflows," or "auditable agent chains" in AI governance papers. Look for gaps in LangSmith or Arize Phoenix specifically regarding long-duration, multi-agent state transitions.

**Scores:** (filled)
- Pain Severity: 
- Gap Uniqueness: 
- Addressability: 
- Ecosystem Timing: 
- Leverage: 
- Han's Edge: 
- **Raw total:** 
- **Final score:** 

**Notes:** 
- 


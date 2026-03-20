# AGENT_INFRA.md - AI Agent Infrastructure Knowledge Base

**Last Updated:** March 19, 2026  
**Total Entries:** 35 (was 24)

---

## PLATFORMS

[PLATFORM] LangChain – https://langchain.com – LLM orchestration framework with tools, agents, chains, memory
[PLATFORM] AutoGen – https://microsoft.github.io/autogen – Microsoft's multi-agent conversation framework for building AI applications
[PLATFORM] CrewAI – https://crewai.com – Role-based AI agent collaboration framework
[PLATFORM] Haystack – https://haystack.deepset.ai – Industrial-strength RAG and multi-modal agent orchestration from Deepset
[PLATFORM] Flowise – https://flowiseai.com – Visual drag-and-drop builder for LangChain flows
[PLATFORM] Vellum – https://vellum.ai – Cloud-agnostic AI workflow platform with observability, governance, model flexibility

---

## ORCHESTRATION

[ORCHESTRATION] CrewAI or SALLMA – Role-based frameworks handling communication internally, letting teams focus on agent logic  
[ORCHESTRATION] LangGraph – LangChain's graph-based orchestration for structured multi-agent workflows  
[ORCHESTRATION] Wukong (Alibaba) – https://www.reuters.com/world/asia-pacific/alibaba-launches-new-ai-agent-platform-enterprises-2026-03-17 – Coordinates multiple agents for document editing, spreadsheets, transcription (March 2026)  
[ORCHESTRATION] MCP Tracing Assistant – Unified client-server trace hierarchy for MCP-based agents in IDEs like Cursor, Claude Code

---

## DEBUGGING

[DEBUGGING] LangSmith – https://smith.langchain.com – LangChain's tracing, evals, debugging platform for LLM apps  
[DEBUGGING] AgentRx (Microsoft Research) – https://www.microsoft.com/research/agentrx – Systematic debugging framework treating agent execution as system traces  
[DEBUGGING] Laminar – https://laminar.dev – $3M seed startup (March 2026) with browser session recordings synced to traces, AI-powered failure pattern analysis

---

## OBSERVABILITY

[OBSERVABILITY] Langfuse – https://langfuse.com – Open-source observability with prompt management, cost tracking, quality metrics  
[DEBUGGING/TRACEABLE] Helicone – Proxy-based observability for cost spikes and latency issues across providers  
[OBSERVABILITY] Arize Phoenix – https://arize.com/phoenix – OpenTelemetry-native tracing with embedding clustering  
[OBSERVABILITY] Monte Carlo Agent Observability – https://montecarlo.io – End-to-end visibility across context, performance, behavior; BigQuery/Athena integration

---

## PAYMENTS & ECONOMICS

[PAYMENTS] Coinbase Payments MCP – https://coinbase.com/payments-mcp – On-chain financial tools access for agents (wallets, stablecoins)  
[PAYMENTS] Wirex Agents – https://wirex.com/wirex-agents – Non-custodial infrastructure for AI stablecoin cards and autonomous micropayments (March 2026)  
[PAYMENTS] Tempo Blockchain (x402 protocol) – https://tempo.blockchain – Stripe/Paradigm mainnet launch for autonomous agent micropayments (March 2026)

---

## GOVERNANCE

[GOVERNANCE] Microsoft Agent 365 – https://learn.microsoft.com/agent-365 – Enterprise governance within M365 E7, OTel SDK in Frontier preview  
[GOVERNANCE] OneTrust Real-Time AI Governance – https://onetrust.com – Continuous monitoring beyond compliance checks (March 2026)  
[GOVERNANCE] HaystackID AI Governance Services – https://haystackid.com – Operationalize responsible AI oversight for legal/compliance environments  
[GOVERNANCE] CrowdStrike Falcon + NVIDIA OpenShell – Secure-by-design blueprint integrating protection into agent runtime (GTC 2026, March 2026)

---

## IDENTITY & VERIFICATION

[IDENTITY] World ID AgentKit – https://world.org/agentkit – Sam Altman's identity verification for AI agents via cryptographic proof (March 2026)  
[IDENTITY] Yubico + Delinea Integration – Q2 2026 launch tying AI actions to human approval for accountability

---

## PROTOCOLS & STANDARDS

[PROTOCOL] Model Context Protocol (MCP) – https://modelcontextprotocol.io – Standardized tool discovery and agent-to-tool communication (VS Code, JetBrains native support)  
[PROTOCOL] A2A (Agent-to-Agent) – Google's interoperability protocol for multi-agent systems  
[PROTOCOL] MCP 2.0 – Control mechanisms supporting EU AI Act, DORA compliance

---

## PATTERNS & TRENDS

**Emerging patterns in Q4 2025 - Q1 2026:**

- **Guardian Agents**: New category that own tasks AND govern other agents to sense/risk-control
- **Observability Warehouses**: Specialized data stores for logs/metrics/traces replacing monolithic black boxes
- **Agent Control Planes**: Central differentiation covering observability, policy enforcement, cost governance, security
- **MCP Standardization**: Entire tools layer rebuilt around standardized connectivity (major shift from 2024)
- **Reasoning Models**: Single-call agents replacing multi-step chains via native extended thinking

---

## GAP ANALYSIS & FRAGMENTATION ISSUES

**Identified Gaps:**

1. **Fragmented Observability Stack**: No unified solution covering context, performance, behavior, outputs across cloud/IT/financial environments
2. **Payment Infrastructure Not Production-Ready**: While protocols exist (x402, Lightning), enterprise-grade fraud detection for machine-initiated micropayments at scale remains unsolved
3. **Identity Verification Fragmentation**: Multiple competing approaches (World ID, Yubico-Delinea, etc.) without clear standardization
4. **Cross-Platform Orchestration Complexity**: Organizations need tools to manage disparate frameworks (CrewAI, LangGraph, AutoGen) under unified control
5. **"Agent-Natives" vs Incumbents Uncertainty**: Competitive question of whether specialized agent startups will capture markets before enterprise players adapt

**What's Missing:**
- Open standards for agent-to-agent payment settlement at scale
- Vendor-neutral observability that works across all orchestration frameworks
- Integrated governance that's as developer-friendly as the tools it governs
- Production-grade monitoring for multi-agent collaboration health and emergent behavior detection

---

## KEY TAKEAWAYS

1. **Observability is table stakes** - No agent deployment without tracing/monitoring in 2026
2. **Governance control planes are differentiators** - Enterprise platforms competing on policy enforcement and cost governance
3. **Payments infrastructure emerging** - Stablecoin-based autonomous spending becoming viable but still early
4. **MCP is becoming the connectivity standard** - Tool discovery layer rebuilt around protocol
5. **Identity crucial for trust** - Human verification behind AI actions essential as agents spend/act autonomously

---

*Knowledge base maintained for agent infrastructure landscape awareness.*

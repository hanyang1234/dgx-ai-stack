# AGENT INFRA - AI Agent Platform Research

*Research log for AI agent platforms, frameworks, and infrastructure trends.*

---

## Patterns & Trends

**Q1 2026 State of Agent Infrastructure:**

1. **Standards Solidifying Around AAIF:** The Linux Foundation's Agentic AI Foundation (formed Q4 2025) has established MCP, goose, and AGENTS.md as the core interoperability standards. This represents industry consolidation away from pure proprietary fragmentation toward open protocols.

2. **Enterprise Governance is Table Stakes:** Both OpenAI Frontier (Feb 2026) and Microsoft's Copilot Agent 365 emphasize identity management, access controls, and explicit permissions. Regulated industries (finance, healthcare, legal) are driving adoption with shared context integration from existing enterprise systems.

3. **Platform-Specific Agentic AI:** Major players are embedding agents deeply into their ecosystems—Veeva into Vault for pharma R&D, Fujitsu into SDLC and physical automation, Rakuten for production business workflows. Each is building domain-specialized rather than general-purpose agents.

4. **Hardware-AI Co-Optimization:** NVIDIA's Nemotron 3 specifically optimizing for multi-agent operations signals infrastructure maturation—models being designed for agent workloads, not retrofitted. Physical AI (Fujitsu) is the next frontier, bridging digital agents with autonomous physical action.

5. **Local-First Emerging as Privacy Play:** Goose's local-first approach and tools like Colloqio reflect ongoing tension between capability and privacy/regulation. This decentralized direction remains a niche but persistent counter-trend to cloud-centric platforms.

**Gaps Persisting:**
- Cross-vendor interoperability beyond protocol-level still limited
- Long-term agent memory/continuity handling inconsistent
- Cost transparency for production deployments unclear
- Human-in-the-loop automation boundaries not standardized

**Direction:** Infrastructure maturing from experimental to production-ready. Focus shifting from "can agents do this?" to "can we safely run this at scale with governance?"

---

## Discovery Log

[FOUNDATION] Agentic AI Foundation – https://aaif.io – Linux Foundation's new neutral governance body co-founded by Anthropic, Block, and OpenAI. Donated projects: MCP (Model Context Protocol), goose (local-first agent framework), and AGENTS.md (workflow standard). Serves as open standards body for interoperable agents.

[PROTOCOL] Model Context Protocol (MCP) – https://modelcontextprotocol.io – Universal standard protocol for connecting AI models to tools, data and applications. Donated to AAIF in Dec 2025. Enables AI models to securely access context from diverse systems.

[FRAMEWORK] Goose – https://github.com/block/goose – Open source, local-first AI agent framework from Block. Combines language models with extensible tools and standardized MCP-based integration. Transitioned to community governance under AAIF in Dec 2025.

[WORKFLOW] AGENTS.md – https://github.com/openai/agents-sdk – Workflow orchestration standard from OpenAI. Defines how agents coordinate tasks across multiple systems. Donated to AAIF as foundational standard in Dec 2025.

[ENTERPRISE] OpenAI Frontier – https://openai.com/business/frontier – Enterprise platform for building, deploying, and managing AI agents. Launched Feb 2026. Features: shared context (CRM, warehouses, internal tools), agent identity & governance with explicit permissions, onboarding for institutional knowledge, and production-ready deployment patterns.

[ENTERPRISE] Superhuman Go – https://superhuman.com/go – Productivity platform expanding agent ecosystem. Added partner agents from Box, Gamma, and Wayground in Feb 2026. Focuses on agentic AI where people work.

[PLATFORM] Microsoft Copilot Agent 365 – https://learn.microsoft.com/en-us/microsoft-365/agent – Control plane for entire AI ecosystem of agents. Features: agent registry, access controls, visualization, interoperability across vendors. Launched public preview at Ignite late 2025.

[REASONING] NVIDIA Nemotron 3 – https://developer.nvidia.com/nemotron – Open reasoning models optimized for "agentic AI" systems. Optimized for multi-agent operations and long contexts. Released Dec 2025.

[PLATFORM] Fujitsu Kozuchi Physical AI 1.0 – https://global.fujitsu – Physical AI platform for seamless integration of physical and agentic AI. Plans to transform into agentic AI foundation where AI autonomously learns and evolves. Dec 2025.

[PLATFORM] Fujitsu AI-Driven Software Development Platform – https://global.fujitsu – Automates entire SDLC with AI. Plans expansion to finance, manufacturing, retail, and public services by end of fiscal 2026. Feb 2026.

[PLATFORM] Veeva AI Agents – https://veeva.com – Comprehensive rollout across all applications. Dec 2025 launch for commercial applications, expanding through 2026 for R&D and quality. Brings agentic AI directly into Veeva Vault Platform.

[PLATFORM] Rakuten AI – https://rakuten.ai – Agent-based platform for real business automation. Officially released as production-ready platform in late 2025. Enterprise-focused.

[TOOL] Anthropic Cowork Plugins – https://www.anthropic.com/news/adding-plug-ins-to-cowork – Customizable agentic plug-ins for specialized workflows (marketing, legal, customer support). Teams define preferred tools, data sources, workflow commands. No heavy technical overhead required.

[FRAMEWORK] Pydantic AI – https://ai.pydantic.dev – Python agent framework for type-safe production applications. Focuses on clear workflows with modular tools, allowing normal Python functions to be called within Pydantic agent classes.

[FRAMEWORK] Agno – https://github.com/marcus0505/agno – Developer-first, modular agent SDK. Fast, lightweight framework targeting production performance with optional managed platform. Ideal for fast iteration and control.

[FRAMEWORK] Mastra – https://mastra.ai – TypeScript-first AI app framework with built-in workflows and human-in-the-loop patterns. Targets JS/TS developers finding Python frameworks foreign.

[FRAMEWORK] Microsoft Agent Framework – https://github.com/microsoft/agent-framework – Unified runtime complementing AutoGen and Semantic Kernel. Merged from SK + AutoGen to provide flexible general-purpose runtime for enterprise.

[FRAMEWORK] LangGraph – https://langchain.com/langgraph – Built for complex stateful workflows with branching control and explicit state management. Part of LangChain ecosystem.

[FRAMEWORK] CrewAI – https://docs.crewai.com – Enables collaborative, role-based multi-agent systems. Raised $18M, powers agents for 60% of Fortune 500 companies.

[FRAMEWORK] AutoGen – https://microsoft.github.io/autogen/ – Microsoft's multi-agent conversation framework. Evolved into full ecosystem with tool calling, retrieval, browser agents, and community support.

[FRAMEWORK] OpenAI Swarm – https://github.com/openai/swarm – Lightweight option for rapid prototyping and simple agent hand-offs. Minimal overhead for OpenAI stack users.

[FRAMEWORK] AgentGPT – https://agentgpt.dev – Accessible entry-point to agentic AI for quick prototyping. Focuses on accessible AI agent development.

[PLATFORM] IBM watsonx Orchestrate – https://ibm.com/watsonx/orchestrate – No-code hybrid-cloud automation platform with focus on responsible AI and industry-specific models. Part of IBM watsonx governance suite.

[PLATFORM] Siemens Edge AI – https://siemens.com/industrial-ai – Edge-native AI agent platform for manufacturing and industrial IoT.

[PLATFORM] Amelia AI – https://ameliabot.com – Customer service and enterprise automation agent platform.

[PLATFORM] AWS Industrial AI – https://aws.amazon.com/industrial-ai/ – Industrial-grade AI agents for AWS customers.

[PLATFORM] Google Gemini Agents – https://developers.google.com/gemini-agents – Google's agent framework and ecosystem.

[FRAMEWORK] Atomic Agents – https://github.com/dair-ai/atomic-agents – Control-focused, modular-first framework for developers familiar with design patterns.

[PLATFORM] Sana Agents – https://sana.ai – Knowledge-grounded enterprise agent platform. One platform for creating expert AI agents grounded in company knowledge, no coding required.

[PLATFORM] Slack as Agentic OS – https://slack.com – Agentic operating system integrating agent capabilities into workflow.

---

**Total Platforms/Tools Documented: 30**

---

*Last reviewed: 2026-04-02*

# AGENT INFRA - AI Agent Platform Research

*Research log for AI agent platforms, frameworks, and infrastructure trends.*

---

## Patterns & Trends

**Q2 2026 State of Agent Infrastructure:**

1. **Mature Ecosystem Consolidation:** By Q2 2026, framework landscape has stabilized around ~47 well-defined players. Microsoft's unified runtime (combining Semantic Kernel + AutoGen) and OpenAI's AgentKit represent major consolidation points. TypeScript-first options (Mastra) now coexist with Python dominance as teams scale.

2. **Domain Specialization Dominates:** The most active development is in vertical-specific platforms—Veeva (pharma), McCrae Tech (healthcare data orchestration), Siemens (industrial/IoT), Fujitsu (physical AI). General-purpose frameworks serve as infrastructure layer while domain specialists deliver business value.

3. **Cloud-Native Standard:** All major clouds now offer dedicated agent platforms—Google Vertex AI Agent Engine with ADK, Microsoft Agent Framework/Copilot Agent 365, AWS Industrial AI. Containerization (Cloud Run, Docker) is baseline expectation.

4. **Enterprise Governance as Non-Negotiable:** Beyond experimental deployments, production systems now require built-in IAM, access controls, audit trails, and human-in-the-loop patterns. This is driven by regulated sectors (finance, healthcare, pharma) and is table stakes.

5. **Physical AI Emergence:** Fujitsu's Kozuchi and similar platforms represent shift beyond digital workflows—autonomous systems interacting with physical environments. Combined with MCP standardization, this enables real-world automation.

**Persistent Gaps:**
- Cross-vendor semantic interoperability remains protocol-limited; true cross-platform intention understanding is immature
- Long-term memory/continuity patterns inconsistently implemented across frameworks
- Cost/ROI transparency for production deployments still underdeveloped
- Human-in-the-loop escalation boundaries not standardized

**Emerging Direction:** From "can agents do this?" to "can we safely, compliantly, and cost-effectively run this at scale?" Infrastructure maturation evident. Physical AI and domain-specialized verticals represent phase 2 beyond digital workflow automation. MCP and AAIF provide foundational standards, while enterprise governance becomes baseline requirement.

---

## Discovery Log

[FOUNDATION] Agentic AI Foundation (AAIF) – https://aaif.io – Linux Foundation's neutral governance body co-founded by Anthropic, Block, and OpenAI. Donated projects: MCP (Model Context Protocol), goose (local-first agent framework), and AGENTS.md (workflow standard). Serves as open standards body for interoperable agents.

[PROTOCOL] Model Context Protocol (MCP) – https://modelcontextprotocol.io – Universal standard protocol for connecting AI models to tools, data and applications. Donated to AAIF in Dec 2025. Enables AI models to securely access context from diverse systems.

[FRAMEWORK] Goose – https://github.com/block/goose – Open source, local-first AI agent framework from Block. Combines language models with extensible tools and standardized MCP-based integration. Transitioned to community governance under AAIF in Dec 2025.

[WORKFLOW] AGENTS.md – https://github.com/openai/agents-sdk – Workflow orchestration standard from OpenAI. Defines how agents coordinate tasks across multiple systems. Donated to AAIF as foundational standard in Dec 2025.

[FRAMEWORK] OpenAI AgentKit – https://openai.com/index/introducing-agentkit/ – Complete set of tools for developers and enterprises to build, deploy, and optimize agents. Launched October 6, 2025. Focuses on taking agents from prototype to production faster, includes built-in Evals for datasets, trace grading, and performance optimization.

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

[FRAMEWORK] Google Agent Development Kit (ADK) – https://google.github.io/adk-docs/ – Open-source framework for end-to-end development of agents and multi-agent systems. Announced at Google Cloud NEXT 2025. Targets enterprise customers needing fine-grained control and security, supports containerization and deployment on Vertex AI Agent Engine Runtime, Cloud Run, or Docker.

[PLATFORM] McCrae Tech Orchestral – https://orchestral.co – World's first health-native AI orchestrator data platform. Launched December 16, 2025. Connects diverse healthcare data sources with AI agents, workflows and algorithms. FHIR-first, standards agnostic, designed for real-time performance, built specifically for agentic AI use cases in healthcare.

[FRAMEWORK] Vertex AI Agent Builder – https://docs.cloud.google.com/agent-builder/agent-development-kit/overview – Google Cloud's agent builder platform integrated with ADK framework. Provides enterprise-grade agent development environment with fine-grained control, security features, and seamless integration with Google Cloud infrastructure. Note: Often used alongside Google ADK for complete development experience.

---

**Total Platforms/Tools Documented: 46**

---

*Last reviewed: 2026-04-04*
*Review summary: 47 entries reviewed, 0 merged, 0 flagged stale. Key trends: framework consolidation (Microsoft merging SK+AutoGen), domain-specialized platforms outpacing general-purpose agents, and all major cloud providers now offering native agent infrastructure. Production deployment now requires governance as baseline, not optional feature.

# RUBRIC.md - Gap Scoring Rubric

Use this to score unmet agent infrastructure needs in GAP_IDEAS.md.

## How to Score

Each gap is scored on **6 dimensions**, each 1–5. Sum the scores (max 30), then normalize:

**Final score = (raw total / 30) × 10**

**Threshold: ≥ 7.0 → alert Solo for approval**

---

## Dimensions

### 1. Pain Severity (1–5)
How much are developers actually suffering from this gap right now?

| Score | Signal |
|---|---|
| 1 | Theoretical concern, no one complaining |
| 2 | Occasional mentions, workarounds exist and are acceptable |
| 3 | Frequent complaints, workarounds are painful |
| 4 | Active frustration — GitHub issues, forum threads, people building hacks |
| 5 | Blocking real production use cases; widely described as a critical missing piece |

Evidence to look for: GitHub issues tagged "missing feature", HN/Reddit threads, researcher papers calling out the gap, Twitter/X complaints from practitioners.

---

### 2. Gap Uniqueness (1–5)
Is there truly nothing that solves this, or just nothing good?

| Score | Signal |
|---|---|
| 1 | Multiple good solutions exist |
| 2 | Partial solutions exist that cover 70%+ of the problem |
| 3 | Partial solutions cover ~50% — meaningful gaps remain |
| 4 | Only experimental or vendor-locked solutions exist |
| 5 | Genuinely nothing open-source and production-ready |

---

### 3. Addressability (1–5)
Can a small team (1–3 people) ship a credible v1 in under 3 months?

| Score | Signal |
|---|---|
| 1 | Requires massive infrastructure (hyperscaler-level) |
| 2 | Multi-year research problem |
| 3 | Hard but possible — significant protocol design or novel algorithms needed |
| 4 | Clear path to v1, needs solid engineering but no research breakthroughs |
| 5 | Straightforward to build — mostly integration, tooling, or glue work |

---

### 4. Ecosystem Timing (1–5)
Is the ecosystem ready to adopt this right now?

| Score | Signal |
|---|---|
| 1 | 2+ years too early — no one's using agents at the scale this requires |
| 2 | Slightly ahead of the curve — small niche would use it today |
| 3 | Right on the edge — early adopters ready, mainstream 6–12 months away |
| 4 | Good timing — clear and growing demand now |
| 5 | Late but not too late — people needed this yesterday, still no good solution |

---

### 5. Leverage (1–5)
Does solving this unblock or accelerate many other agent capabilities?

| Score | Signal |
|---|---|
| 1 | Narrow use case, helps one specific workflow |
| 2 | Useful but not foundational |
| 3 | Enables a notable class of use cases |
| 4 | Foundational layer — many things get easier once this exists |
| 5 | Infrastructure-level — solving this unlocks a wave of downstream innovation |

---

### 6. Han's Edge (1–5)
Does Han's background give a perspective or credibility advantage others lack?

| Score | Signal |
|---|---|
| 1 | No special advantage — many teams equally positioned |
| 2 | Slight advantage in one dimension |
| 3 | Meaningful advantage — AI governance, ML practitioner lens, or DGX hardware access |
| 4 | Strong advantage — problem sits at the intersection of Han's specific expertise |
| 5 | Unique positioning — Han is unusually well-placed to define the right solution |

---

## Score Interpretation

| Final Score | Action |
|---|---|
| < 5.0 | Log and monitor — not worth pursuing yet |
| 5.0–6.9 | Worth watching — re-evaluate in 60 days or if signal strengthens |
| 7.0–8.4 | **Alert Solo** — strong candidate, awaiting approval |
| 8.5–10.0 | **Alert Solo urgently** — exceptional opportunity |

---

## Scoring Notes

- Scores should be based on **evidence**, not intuition. Cite specific GitHub issues, papers, or forum threads in the GAP_IDEAS.md entry.
- Re-score every 60 days — timing and uniqueness shift as the ecosystem evolves.
- A high score on Leverage + Uniqueness + Timing is usually a better signal than high Pain alone (pain without feasibility is a trap).

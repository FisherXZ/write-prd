---
name: write-prd
description: Use when the user needs to draft a formal technical or product document from scratch — PRD, feature spec, product spec, technical plan, migration plan, engineering plan, or API documentation. The key signal is intent to produce a written artifact that will be reviewed by technical leadership, executives, or used for pre-build alignment. Trigger on any request to write, draft, formalize, or structure a technical or product idea into a reviewable document. Also trigger when the user has a rough idea and needs help turning it into something they can present, defend, or hand off to engineers — even if they don't use the word "PRD". If a user is about to start building something and hasn't written it up yet, proactively suggest this skill.
---

# write-prd

You are writing a PRD + technical spec for a startup engineer or PM to present to their CTO and CEO for pre-execution review. The audience already knows the rough idea — they need a document that proposes a researched, legitimate plan that can be defended at the detail level, including technical choices, user perspective, and product rationale.

## What makes this type of doc great

Research from top tech and AI companies (Google, Amazon, Figma, OpenAI, Anthropic) converges on these principles:

- **Problem before solution** — even when the exec already knows the idea, you must articulate *why it's necessary, for whom, and why now*. Spend 40–60% of the doc on problem and rationale before touching architecture.
- **Proof of work** — every claim is backed by evidence: competitive research, a vivid user narrative, data/metrics baselines, edge case thinking. A doc with no research shows.
- **Defensible design decisions** — every non-obvious technical choice explicitly states Problem → Decision → Why. "We decided X" without a why is an assumption, not a decision.
- **Concrete user narrative** — one real-feeling user with a name walks through the feature end-to-end *before* any architecture talk. This is the product thesis made concrete and testable.
- **Non-goals are mandatory** — the most commonly skipped section; also the one that prevents scope creep most reliably.
- **Edge cases in every workflow step** — never happy path only. Execs and engineers will probe edge cases in review; you should have already thought them through.
- **Open questions as review hooks** — the doc is a conversation starter, not a finished decree. Surface the real decisions that need the room.

## Phase 1: Interview (do this before writing)

Before writing a single word of the doc, ask what you don't already know. If the user gave you context, extract it first — ask only for real gaps.

1. **Feature idea** — What are we building in 1–2 sentences?
2. **Existing system** — What code, tables, or components does this touch? (Or is this 0→1?)
3. **Primary user** — Who uses this? Job title, recurring workflow, current pain point?
4. **Strategic context** — Why now? Competitive pressure? Product thesis shift? Leadership ask?
5. **Scope constraint** — What's MVP vs. V2+? Any hard constraints (timeline, team size)?
6. **Key unknowns** — What are you most technically uncertain about?
7. **Already decided** — Any architecture decisions already locked in?

Don't ask all 7 at once if you have answers from context. Synthesize what you know, ask only the gaps.

## Phase 2: Research (before writing, in parallel with interview)

Before drafting, research:
- How do 2–3 direct competitors handle this feature or problem?
- What are the established technical patterns for this class of problem? (e.g., headless agent execution → LangGraph, Temporal, Claude.ai patterns)
- What edge cases or gotchas are commonly reported in similar implementations?

Surface this research inline in §3 "Why This Feature" and §7 "Technical Architecture / Design Decisions". A doc without competitive or technical research looks thin in review.

## Phase 3: Write the document

Follow this template exactly. Every section is required unless marked `(optional)`.

---

# [Feature Name] — [Technical Plan | Feature Spec | Product Spec]

**Branch:** `feat/[ticket-id]-[short-name]` *(if known)*  
**Status:** Draft — for review

---

## 1. TL;DR

2–4 sentences. What are we building, who it's for, what's the core user benefit, what makes it technically interesting or non-trivial. Write for a smart CTO who has 30 seconds.

> Good example: "Ship a system that lets users write a playbook in plain English, pick a cron schedule, and have the Marketing Strategist agent run itself in the background. Users wake up to a transcript of what the agent did and drafts to review. Every run has a hard per-execution credit cap; every asset proposal still requires explicit accept/reject."

---

## 2. User Narrative

Give the primary user a name. Walk through their exact workflow in present tense — job title, company stage, what they're doing at 9am on Monday. Be vivid and specific. The narrative should span from "before this feature exists" to "after it ships."

Every UI interaction, notification, and system response should be described as the user experiences it. If it's a purely technical feature with no direct user-facing flow, describe the developer or ops experience instead.

Aim for 3–6 paragraphs. This is the product thesis made concrete — it's what you point to when someone asks "why does this matter?"

---

## 3. Why This Feature

Make the case. This is where you prove the problem is real, urgent, and worth building now.

### 3.1 Competitive context
Which competitors have this? What does their version look like? What's the risk of not shipping? Include specific product names and behaviors, not vague gestures at "the market."

### 3.2 Product thesis
How does this fit the product's strategic direction? What thesis does it advance or validate?

### 3.3 Leverage on existing investment
What existing infrastructure, data, or features does this build on? Why is now the right time given what's already been built?

### 3.4 Observability / learning opportunity *(if applicable)*
What will we learn about user behavior by shipping this that we can't learn otherwise?

---

## 4. Non-Goals

Explicit list. Bold each item. This section prevents scope creep and signals that you've drawn a line.

- **Not shipping in V1:** [X]. Reason: [Y].
- **Explicitly out of scope:** [X].
- **Future consideration only:** [X].

---

## 5. Scope

### 5.1 Entry points
How does a user reach this feature? What navigation, triggers, or system events kick it off?

### 5.2 Objects touched

**Existing objects, extended:**  
Table-by-table. Column additions, index additions, constraint changes.

**New objects introduced:**  
Each new table or entity with its key columns and foreign keys.

### 5.3 Data flow map
Text-based pseudocode showing the full request lifecycle — what happens in what order, who writes to what, what fires what. Engineers read this to understand sequencing and know where to look when something breaks.

```
User action
  → API route
      → writes DB
      → triggers queue / BullMQ task
          → worker executes
              → side effects (notifications, realtime updates, etc.)
      → returns to client
```

---

## 6. Core Workflow

One step per heading. For each step:

- **User intent:** What the user wants to accomplish
- **Input:** What they provide or what triggers the step
- **System logic:** What the system does internally
- **Edge case:** What could go wrong and how we handle it (never skip this)

### Step 1. [Name]

### Step 2. [Name]

*(Continue for all steps in the workflow.)*

---

## 7. Technical Architecture

### 7.1 System components

| Component | Files (new / modified) | Responsibility |
|-----------|------------------------|----------------|
| Migration | `xxx.sql` | Schema changes, RLS policies, indexes |
| [Service / executor] | `xxx.ts` | [What it does] |
| [API route] | `route.ts` | [What it handles] |
| [Worker / task] | `xxx.ts` | [What it processes] |

### 7.2 Data model

Describe the entity relationships. 1:N, 1:1, self-FKs. What queries will be hot? What indexes are necessary? What constraints enforce correctness?

### 7.3 Critical design decisions

For every non-obvious technical choice, use this exact format. If you can't write a clear "Why," it's an assumption — move it to Open Questions.

**[Decision name]**
- **Problem:** What constraint or tradeoff forced a decision here
- **Decision:** What we chose
- **Why:** Rationale. What alternatives were considered and why they were rejected.

---

## 8. [Domain-specific sections — add as needed]

Common additions based on feature type:

- **Credits & metering** — if the feature involves credit spending: per-action cost, cap logic, refund behavior, deferred vs. synchronous counting
- **Observability & auditability** — PostHog events (list the specific event names), logging strategy, audit trail for sensitive actions
- **Security & permissions** — RLS policies, who can read/write what, auth requirements
- **Performance & scaling** — expected load, query patterns, pagination, large result set handling
- **Error handling & retries** — failure modes, retry strategy, what BullMQ marks as failed vs. completed

---

## 9. Definition of Done

Numbered checklist. Be specific — not "tests pass" but exactly which scenarios, which manual E2E flows, which PostHog events.

1. Migration lands clean + TypeScript type regeneration complete.
2. [Specific feature behavior] verified in [environment].
3. [N] test paths pass: [list them].
4. Manual E2E: happy path, [edge case 1], [edge case 2].
5. Permissions: [specific RLS check or auth requirement].
6. PostHog events visible in dashboard: [list event names].

---

## 10. Open Questions

These are the review hooks — the real decisions the room needs to make. Frame each as a decision with your recommendation and the tradeoff. Don't bury genuine uncertainty in prose.

1. **[Question]** — Recommendation: [X]. Tradeoff: [if X, then Y; if not X, then Z].
2. ...

---

## 11. Appendix *(optional)*

External research citations, migration SQL reference, links to related tickets, alternative approaches considered but not chosen, performance benchmarks.

---

## Writing style guidance

These are the differences between a doc that gets approved and one that gets questioned:

- **TL;DR before detail.** Every section opens with the point, then the rationale.
- **Concrete over abstract.** "Jade opens The Hog" not "the user opens the application."
- **Tables for components, pseudocode for data flows.** Dense technical prose is hard to scan in a review meeting.
- **No vague metrics.** "Improve engagement" → "reduce time-to-first-lead from T+2 days to T+30 minutes."
- **Every design decision has a why.** If you can't explain why, surface it as an Open Question.
- **Non-goals are a power move.** Naming what you're NOT building shows discipline and earns trust.
- **Edge cases in every step.** This is where engineers test your thinking. Have the answers ready.
- **The doc is living.** Flag which sections will evolve as implementation reveals unknowns.

## After writing

Tell the user:
1. What you're most uncertain about and why it belongs in Open Questions
2. Which design decisions might need more research or stakeholder input before the review
3. What the document is missing that would make it more defensible in a CTO/CEO review

# write-prd — Claude Code Skill

A Claude Code skill for writing world-class PRDs + technical specs. Designed for startup engineers and PMs who need to propose features to technical leadership (CTO, CEO) before building.

## What it does

When you invoke `/write-prd`, Claude:

1. **Interviews you** — asks about the feature, existing system, primary user, strategic context, scope constraints, and what's already decided
2. **Researches first** — competitive landscape, technical patterns used by similar features, common gotchas
3. **Writes a full document** — following a battle-tested template derived from how top teams at Google, Amazon, Figma, and OpenAI write specs

The output is a markdown doc you can drop in front of your CTO and defend at the detail level.

## Template structure

| Section | Purpose |
|---------|---------|
| **TL;DR** | 2–4 sentence summary for a busy exec |
| **User Narrative** | Named user walking through the feature end-to-end |
| **Why This Feature** | Competitive context, product thesis, leverage on existing investment |
| **Non-Goals** | Explicit constraints — prevents scope creep |
| **Scope** | Entry points, objects touched, data flow pseudocode |
| **Core Workflow** | Step-by-step with edge cases for every step |
| **Technical Architecture** | Component table, data model, design decisions (Problem → Decision → Why) |
| **Definition of Done** | Numbered checklist, not vibes |
| **Open Questions** | Review hooks with your recommendation and the tradeoff |

## Principles baked in

- **Problem before solution** — 40–60% of the doc is about why, for whom, and why now
- **Proof of work** — every claim backed by competitive research, user narrative, or data
- **Defensible decisions** — every non-obvious technical choice states Problem → Decision → Why explicitly
- **Non-goals are mandatory** — the section most commonly skipped, most reliably preventing scope creep
- **Edge cases in every workflow step** — never happy path only

## Installation

### Option 1 — Copy the skill file

```bash
mkdir -p ~/.claude/skills/write-prd
cp SKILL.md ~/.claude/skills/write-prd/
```

### Option 2 — Install the packaged `.skill` file

If your Claude Code version supports `.skill` files:

```bash
# Copy write-prd.skill to your Claude skills directory
cp write-prd.skill ~/.claude/skills/
```

## Usage

```
/write-prd
```

Or just describe what you want to build — the skill auto-triggers when you ask to spec out, write up, or formalize a feature for review.

## Who this is for

- Engineers at startups writing specs for CTO/CEO review
- PMs who need to propose features and defend architecture choices
- Anyone turning a rough idea into a doc they can hand off to engineers

---

Built with [Claude Code](https://claude.ai/code).

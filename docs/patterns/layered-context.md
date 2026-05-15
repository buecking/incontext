---
title: Layered context
layout: default
parent: Patterns
nav_order: 2
permalink: /docs/patterns/layered-context/
---

# Layered context
{: .no_toc }

1. TOC
{:toc}

---

Don't carry one big block of context. Stack three: **global → project → task**, each updated on its own cadence, each overriding the layer below where they conflict. Closer-to-now wins.

This is how every AI coding tool actually loads its context today, whether the docs call it "layered" or not. Making the layering explicit lets you tune what changes how often, which is the lever that determines cache hit rate and adherence.

## The three layers

The names vary by tool but the shape is consistent:

| Layer | Cadence | Lives in (Claude Code) | Example content |
|---|---|---|---|
| **Global** | Rarely changes | `~/.claude/CLAUDE.md`, managed policy | Personal preferences, org-wide standards |
| **Project** | Per-feature | `./CLAUDE.md`, `.claude/rules/` | Stack, build commands, conventions, architecture |
| **Task** | Per-turn | The user message; `perception.md`; tool results | The current story, the current file, the next action |

Every tool implements roughly this. Claude Code names them *managed* → *user* → *project* → *local* and loads them in that order ([memory docs](https://code.claude.com/docs/en/memory)). Cursor's rule types — Always, Auto Attached, Agent Requested, Manual — are a different cut of the same idea. GitHub Copilot has personal → repository → organization. The pattern survives every tool's specific vocabulary.

## Why layering matters

The single most important property of context, post-2024, is **how often it changes**. Anthropic's prompt caching ([docs](https://docs.anthropic.com/en/docs/build-with-claude/prompt-caching)) — and every other provider's equivalent — reuses the KV cache for stable prefixes. Edit a token early in the prompt and the entire cache from that point on is invalidated.

This means: **the order of your layers determines your cache cost**. Stable content at the top, volatile content at the bottom.

The natural mapping:

```text
┌─────────────────────────────────┐
│ Global (changes ~never)         │  ← cached for hours, sometimes days
├─────────────────────────────────┤
│ Project (changes per-feature)   │  ← cached for the duration of a feature
├─────────────────────────────────┤
│ Task (changes per-turn)         │  ← rarely worth caching at all
└─────────────────────────────────┘
                 ↓
            user message
```

Reverse this — task-level on top, global at the bottom — and you've defeated the cache entirely. Every turn invalidates everything.

## Override behavior

The rule across every major tool: **the most-specific (closest to now / closest to the working directory) layer wins on conflict.**

- **Claude Code:** managed → user → project → local, with local winning. ([source](https://code.claude.com/docs/en/memory))
- **GitHub Copilot:** "Personal instructions take the highest priority. Repository instructions come next, and then organization instructions are prioritized last." ([source](https://docs.github.com/en/copilot/customizing-copilot/adding-custom-instructions-for-github-copilot))
- **AGENTS.md:** "the closest one takes precedence" for nested files. ([spec](https://agents.md/))

When in doubt: closer wins.

## How to apply it

Three actionable rules.

### 1. Push every fact to the lowest layer that contains it

Don't put a stack version in your personal `~/.claude/CLAUDE.md` — it belongs in the project. Don't put a project's testing convention in `~/.claude/CLAUDE.md` either. Each fact has exactly one correct layer.

Quick test: *"If I changed jobs tomorrow and started a new project, would this rule still be true?"*

- Yes → global.
- Only for some projects → project.
- Only for this slice → task.

### 2. Match update cadence to layer

If you find yourself editing `~/.claude/CLAUDE.md` weekly, those edits belong in a project file. If you find yourself editing the project `CLAUDE.md` mid-session, those edits belong in the task layer (a user message, a `perception.md`, a slash-command prompt).

The economics: every layer edit invalidates the cache from that point down. Frequent edits to a high layer are expensive. Move volatile content down.

### 3. Make the task layer explicit

Most teams have a global layer (`~/.claude/CLAUDE.md`), a project layer (`./CLAUDE.md`), and an implicit task layer (whatever the user types in the next message). The implicit task layer is fine for one-shot tasks. For long-running work, it isn't enough.

A maintained `perception.md` ([Perception over history](/docs/foundations/perception-over-history/)) is one way to give the task layer durable structure. The three perception layers — Invariants / Frame / Working set — map to the three context layers — Global / Project / Task — almost exactly. That's not a coincidence; both are responses to the same cache-and-attention economics.

## Failure modes

- **Layer leakage.** A global rule that's actually project-specific contaminates every project you ever work on. Audit your `~/.claude/CLAUDE.md` quarterly for anything that doesn't actually generalize.
- **Conflict opacity.** Two layers contradict each other and you don't know which won. Run `/memory` (Claude Code) or the equivalent to see exactly what's loaded. See [failure modes §4](/docs/reference/failure-modes/#4-instruction-conflict).
- **Phantom layers.** A rule in `~/.claude/CLAUDE.md` that contradicts a project rule, where you forgot the global rule existed. The closer (project) wins, but you'll be confused why the agent ignores your "global" rule in some projects.
- **Stale upper layers.** Global rules go stale most quietly because you touch them least. The conventions you wrote into `~/.claude/CLAUDE.md` two years ago may not match the conventions of any project you currently work on.

## Related

- [Scope by directory](/docs/patterns/scope-by-directory/) — the directory-tree case of layering
- [Perception over history](/docs/foundations/perception-over-history/) — the task layer designed as a working belief state
- [Front matter cheat sheet](/docs/reference/front-matter/) — the per-tool field reference for each layer
- [Context is a budget](/docs/foundations/context-is-a-budget/) — why layering pays off
- [Failure modes §4 — instruction conflict](/docs/reference/failure-modes/#4-instruction-conflict)

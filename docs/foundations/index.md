---
title: Foundations
layout: default
nav_order: 2
has_children: true
permalink: /docs/foundations/
---

# Foundations

The vocabulary and the underlying ideas. Most of the per-tool, pattern, and skill pages assume the framing on this page; read it first if anything later doesn't make sense.

## What this site is a bet on

For three years the work was called *prompt engineering*. The phrase covered everything from "phrase your question better" to "wrap the answer in JSON" to "give the model a persona." Then the work outgrew the phrase, and around 2024 the field started saying *context engineering* — admitting that the thing you tune isn't a sentence, it's a layered, scoped, time-varying body of material the model reads alongside whatever you're asking.

That rename was the right move. It is also not the last one.

The next shift is already visible in the failure modes of every long-running agent. Conversation grows, context fills, the agent forgets what it was doing, and the standard answer — compress the history, summarize, retrieve — turns out to be solving the wrong problem. The agent doesn't need its history. It needs a current model of where it is, what's true, and what it's about to do.

**The bet this site is built on: the unit of intelligence is not the model. It is the model plus its context apparatus.** A better apparatus on the same model beats a better model on a worse apparatus, and the gap is widening.

## The diagnosis

Today's agents run on a single undifferentiated stream. System prompt, conversation history, tool results, retrieved chunks, file contents — all jammed into one context window, all competing for the same attention, all subject to the same [lost-in-the-middle](/docs/foundations/long-context-degradation/) decay. It is roughly how a person with severe anterograde amnesia tries to do their job: re-reading the diary every five minutes to figure out where they are.

Humans don't run on one stream. We have at least five distinct memory systems, each with its own lifetime, structure, and update rule:

- **Working memory** — small, volatile, refreshed continuously. Holds *what I am doing right now*.
- **Semantic memory** — slow to form, slow to forget. Holds *what is true* about the world.
- **Procedural memory** — encoded by repetition, runs without conscious access. Holds *how to do things*.
- **Episodic memory** — what happened, where, when. Durable, searchable, decays on a schedule.
- **Forward models** — the imagined consequence of an action before you take it.

These are not metaphors. They are separate neural systems, with different anatomies and different failure modes. The reason a person with advanced Alzheimer's can still play piano while forgetting their grandchildren's names is that procedural memory and declarative memory are *different machinery*. One can be damaged without the other.

Everyday language hides this. Most discussion of "AI memory" treats it as one thing. It isn't, and it never was.

## The map

Match today's context tools to the memory systems and the gaps become legible.

| Memory system | Today's analogue | State of the art |
|---|---|---|
| Semantic | `CLAUDE.md`, `AGENTS.md`, Cursor rules | Flat markdown, manual maintenance, no decay or consolidation. Primitive but the role is right. |
| Procedural | Skills (`SKILL.md`), slash commands | Named, reusable workflows, loaded on demand. Closer to muscle memory than to knowledge. |
| Working | `perception.md` (proposed) | Belief state instead of transcript. [Designed here](/docs/foundations/perception-over-history/), not yet deployed in production. |
| Episodic | — | No real implementation. Compaction is lossy stream compression; chat history is a log. A real episodic memory would be durable, indexed by event-context, decay on a schedule, and be queryable on demand. The slot is empty. |
| Forward models | — | No durable implementation. The agent can plan inside its working context, but no surface holds *"if I did X, the consequence would be Y"* across sessions. Hooks and tool-call gates are early gestures. The full thing is missing. |

That is the shape of the gap. The [patterns](/docs/patterns/) elsewhere on this site — layering, scope-by-directory, cite-don't-summarize, retrieve-before-generate, role + task + constraints — are the local choices that build the apparatus. The [failure modes](/docs/reference/failure-modes/) are what goes wrong when the apparatus is wrong. The [skills](/docs/skills/) are the procedural layer. The [reference](/docs/reference/) is the spec.

## Where this is going

If the trajectory closes the gap, the next few years will fill in the missing systems. Working memory will get the layering treatment first — it is the most painful gap, and the cleanest to fix with the tools already in hand. Episodic memory will arrive next, probably as something between a journal and a database, with deliberate decay built in. Forward models will come last and look the strangest at first; there isn't yet a name for what a durable, externalized imagination layer should look like.

The teams that win this period will treat the context apparatus the way operating-system designers treat memory hierarchies: as a thing with structure, with lifetimes, with deliberate tradeoffs. The model is the engine. Everything around the model is the cognitive architecture. *Designing an agent* stops looking like prompt-writing and starts looking like designing a small operating system.

The endpoint — if there is one — is not "the model gets smart enough to not need any of this." It is the opposite. Enough of the apparatus exists that you stop noticing the model. You notice the agent.

Which means, in a real sense: enough of the apparatus exists that the agent is recognizably *like us*. Not because the goal is to copy biology. Because the constraints — finite attention, finite time, finite memory, an unbounded world — are the same.

## Sources

The multiple-memory-systems framework is standard in cognitive neuroscience. The specific five-bucket grouping above is an engineering-oriented synthesis — not a one-to-one mapping to any single paper, but consistent with the literature. The point is functional: these capabilities are *separable* in humans, with different update rules and failure modes. Real AI memory systems should be separable too.

- Squire, L. R. (2004). *Memory systems of the brain: A brief history and current perspective.* Neurobiology of Learning and Memory 82, 171–177 — the declarative / non-declarative split.
- Baddeley, A. (1992). *Working memory.* Science 255, 556–559 — the working-memory model.
- Wolpert, D. M., Ghahramani, Z., & Jordan, M. I. (1995). *An internal model for sensorimotor integration.* Science 269, 1880–1882 — the forward-model framework, originally from motor control, now generalized in predictive-processing accounts.
- Anthropic (2025). *Effective Context Engineering for AI Agents.* <https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents> — the "context rot" frame and the case for minimal viable tool sets.
- Kaelbling, L. P., Littman, M. L., & Cassandra, A. R. (1998). *Planning and acting in partially observable stochastic domains.* Artificial Intelligence 101, 99–134 — the canonical belief-state reference in reinforcement learning, where the trajectory-vs-state distinction comes from.

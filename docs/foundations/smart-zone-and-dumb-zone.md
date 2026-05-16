---
title: The smart zone and the dumb zone
layout: default
parent: Foundations
nav_order: 4
permalink: /docs/foundations/smart-zone-and-dumb-zone/
---

# The smart zone and the dumb zone
{: .no_toc }

1. TOC
{:toc}

---

## The headline

A model starts every session sharp and gets duller with every token added to its context. The early part of a session — small context, fresh attention — is the **smart zone**. The later part of a session — bloated context, attention spread thin, earlier mistakes still in scope — is the **dumb zone**.

The single most useful operating principle that falls out of this: **finish the work before you leave the smart zone, then reset.** Don't let one session sprawl across three features.

The framing comes from Matt Pocock's walkthrough of his AI coding workflow. It's the same underlying phenomenon as [long-context degradation](/docs/foundations/long-context-degradation/) and [context as a budget](/docs/foundations/context-is-a-budget/), but reframed as a working stance: every action you take is buying you a less capable collaborator on the next action.

## Why it gets worse, not just longer

The intuition that "more context = more knowledge" is the wrong shape. Pocock uses a football-league analogy: adding a team doesn't add one new fixture, it adds a fixture against every existing team. Token interactions scale similarly — every new token has to be related, however weakly, to every other token already in scope. The cost isn't linear in tokens; the *coherence* cost is closer to quadratic.

The practical consequences:

- **Earlier mistakes don't disappear.** A wrong assumption made in turn 3 is still being attended to in turn 30, quietly pulling later answers off course.
- **Instructions decay.** The system prompt is still technically in context, but it's competing with everything you've added since.
- **The model gets cheaper to confuse.** A contradiction it would have spotted on a blank slate slips past on a crowded one.
- **You stop noticing.** The decline is gradual. By the time the output is obviously bad, you're well past the point where a fresh session would have been faster.

## Treat context as units of time

The most useful reframe is to stop counting tokens and start counting *actions*. Each action — each tool call, each file read, each round-trip — is a unit of time you've spent. You only have so many before the model is materially worse at the task than it was at the start.

This changes how you decide what to do next:

- **Is this action load-bearing for the task, or am I exploring?** Exploration belongs in a different session.
- **Will this answer still be useful in 30 actions, or only the next 3?** If only the next 3, do the work now and reset before the next chunk.
- **Am I asking the model to re-derive something I already know?** That's a unit of time spent on nothing.

The discipline is the same one good engineers already apply to meetings: every minute spent has a cost, and the cost compounds.

## Operating in the smart zone

A few habits that keep you there:

- **Plan in one session, implement in another.** Planning sessions go long and conversational; implementation sessions need a model that hasn't been arguing about scope for an hour.
- **Slice work small enough to finish before degradation kicks in.** If you can't, the slice is too big — see [vertical tracer bullets](/docs/skills/xp-workflow/).
- **Prefer `/clear` over `/compact`.** Compaction keeps the rot. A clean reset with a tight handoff prompt almost always beats a 200K-token continuation.
- **Front-load the irreversible decisions.** The model is sharpest in the first few turns. Spend those on the choices you can't easily back out of.

{: .tip }
> When you notice yourself re-explaining something, that's the signal. The model isn't getting confused because the task is hard — it's getting confused because the room is too crowded. Reset.

## What this isn't

This is not an argument against long context. Long context is genuinely useful for retrieval-style tasks where the model needs to look something up and answer once. The smart-zone / dumb-zone framing is about **multi-step working sessions**, where each step depends on the model still being coherent about everything before it. Those degrade in a way that single-shot lookups don't.

## Related

- [Context is a budget, not a bucket](/docs/foundations/context-is-a-budget/) — the underlying economics
- [Long-context degradation](/docs/foundations/long-context-degradation/) — the empirical "lost in the middle" finding
- [The XP workflow](/docs/skills/xp-workflow/) — Beck's discipline, summarized faithfully
- [XP with an AI on the team](/docs/skills/xp-with-ai/) — the spinoff that operationalizes the smart-zone constraint
- [Perception over history](/docs/foundations/perception-over-history/) — a compression strategy that defends against the dumb zone by carrying belief state instead of trajectory

## Sources

- Pocock, M. (2026). *Full Walkthrough: Workflow for AI Coding.* YouTube. <https://www.youtube.com/watch?v=-QFHIoCo-Ko>

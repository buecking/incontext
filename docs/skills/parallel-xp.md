---
title: Parallel XP with token budgets
layout: default
parent: Skills
nav_order: 3
permalink: /docs/skills/parallel-xp/
---

# Parallel XP with token budgets
{: .no_toc }

1. TOC
{:toc}

---

This page picks up where [XP with an AI on the team](/docs/skills/xp-with-ai/) leaves off. The 12-point loop on that page is the single-agent variant: one human, one agent, one slice at a time. This page is the *N-agent* variant — what changes when you want to run several slices in parallel, in separate sessions, without the integrator becoming the next dumb-zone victim.

The frame is unchanged from the rest of the site: **the question isn't how to parallelize. It's how to keep each agent's working context as small as possible.** Parallelism is what falls out when the answer is good.

## The motivating failure

Naive parallelism collapses in the integration step. N agents each finish small, sharp slices in their smart zones. Then one party — usually a human, sometimes a big "coordinator" agent — has to merge the work, reconcile the inconsistencies, run the suite, and reason about the composed result. That party loads everything. That party blows past the smart-zone line. The system that was supposed to keep contexts small produces *one* enormous context as the cost of integration.

Any honest design has to defend that step, not just the worker steps. Everything below works backwards from "the integrator must also stay in the smart zone."

## Four pieces

The variant has four moving parts. None of them is novel in isolation. Their composition — and especially the token-as-unit-of-progress move — is the contribution.

### 1. Stories with token budgets

A story in this variant carries an explicit context budget. The familiar fields (acceptance criteria, definition of done) are still there. The new field is a small budget block:

```
Story: parse-bearer-tokens
Context floor:   ~3.4k   (story card + ADR-014 + auth.rs + tests/auth/*)
Working budget:  ~12k    (3–4× floor — empirical multiplier)
Ceiling:         ~15.4k  (must fit under smart-zone ceiling for target model)
Target model:    claude-sonnet-4-6
ADRs in scope:   ADR-014, ADR-007
```

The fields mean:

- **Context floor** — the load-once cost. Story card, in-scope ADRs, files the agent must read to begin. Deterministic; you can measure it before the session starts with a tokenizer.
- **Working budget** — the empirical multiplier on the floor. What the model will generate (and re-read) during the session. Noisy at first; learned over iterations.
- **Ceiling** — floor + working. Must fit comfortably under the load that keeps the target model in its [smart zone](/docs/foundations/smart-zone-and-dumb-zone/). There is no published number for this — you measure it locally by watching where your own sessions start to drift, and you re-measure when the model changes.
- **Target model** — non-optional. Sonnet's smart-zone ceiling is not Opus's is not Haiku's. A ceiling without a model named is meaningless.

The discipline this enforces: **if a story's ceiling pushes past the smart-zone line, the story is too big.** Slice it, pull fewer files into scope, or compress the ADRs it depends on. The decision is now numerical, not aesthetic.

The budget block is the story's small [forward model](/docs/foundations/#the-map) — a predicted resource cost, made explicit so it can be checked against the actual.

### 2. ADRs as compressed contracts

The contract between parallel slices is carried in [Architecture Decision Records](https://adr.github.io/), written in a deliberately compressed form. Where ADRs are traditionally written *after* a decision as documentation, here they are written *during* planning, as the contract surface the parallel agents will consume.

The reframe worth stating: **ADRs are how the pair's inner discussion becomes a context resource instead of a session memory.** In classic XP, the back-and-forth between two humans at one keyboard — "should we extract this?", "what about the cookie case?", "no, that breaks ADR-7" — happens in air and is lost when the pair leaves. With an agent, the same discussion bloats the session context and gets discarded at `/clear`. An ADR captures the surviving decision in a load-once artifact the next agent can read cheaply.

The compression matters. A bloated ADR doesn't just cost itself — it taxes every story that lists it in scope. Shape:

```
# ADR-014: Auth tokens carried in headers, not cookies
Status: accepted  •  Predecessors: ADR-007  •  Weight: ~280 tok
Decision: bearer tokens in Authorization header
Why: SPA needs cross-domain; cookies need CORS gymnastics
Contract:
  type Token = { ... }
  fn verify(t: Token) -> Result<Claims, AuthError>
Does not decide:
  - token storage on client (story-04 owns this)
  - refresh rotation cadence (deferred — see ADR-019)
Locked in by: tests/auth/integration_test.rs::{bearer_round_trip, expired_rejects}
```

Three lines are load-bearing:

- **Weight** — declared token cost. Every story that includes this ADR pays it. Makes the compression discipline visible.
- **Does not decide** — the negative space. Tells sibling agents they're free to act independently in the unscoped region. This is what makes parallelism safe without sibling context-sharing.
- **Locked in by** — explicit test references. Without these, the ADR drifts from the code silently. With them, the ADR is self-checking: if the named tests die or change shape, the ADR is suspect.

ADRs are inherently DAG-friendly. Each one names its predecessors. The story DAG falls out of the ADR DAG as a side effect; you don't need to draw it separately.

### 3. Velocity in tokens, not points

The Planning Game in classic XP measures velocity in story points. The unit was useful precisely because it was abstract — it forced teams to think in relative complexity rather than absolute time. Tokens are a different kind of abstraction: a *physical resource the model consumes*, directly measurable, with no folklore calibration step.

What changes:

- **Estimates are in tokens** (floor + working budget), per story, per target model.
- **Velocity** is tokens-completed per session, per day, per iteration. The tracker role from [`xp-with-ai`](/docs/skills/xp-with-ai/#the-roles-revisited) now has something quantifiable to track.
- **Estimate vs. actual** logging is mandatory. The first few iterations will be wrong by 2–3× on the working-budget side — load tokens are deterministic but generation is empirical. The correction factor is learned, exactly as Beck describes for time-based estimates.

This also collapses the "should we parallelize this?" question into arithmetic:

- If `floor(A) + floor(B) > smart-zone ceiling` → split into separate worktrees.
- If `floor(A) + floor(B) << smart-zone ceiling` → do sequentially in one session. Worktree overhead isn't worth it.

### 4. The integrator as token-burn watcher

The integrator role is what most write-ups about agent parallelism wave their hands at. It's the load-bearing failure point: someone has to compose the parallel work, and that someone has to stay sharp doing it.

The version that works: a narrow integrator whose context contains *outcomes, not implementations*. It does three things, no more:

1. Pulls completed worktrees, merges in dependency order from the ADR DAG.
2. Runs the full test suite. If anything regresses, posts a one-screen diagnostic (failing test, the two slices that touched the relevant file, the locked-in-by ADR if there is one).
3. Tracks rolling token burn across active worktrees. Warns when any session is heading for the dumb zone — usually the signal that the floor estimate was off and the slice needs to be split mid-flight.

What the integrator never does: read any agent's diffs in detail, hold an opinion on implementation, or arbitrate disagreements between agents. The tests arbitrate. If two slices disagree and tests don't catch it, the tests are wrong — and that's a story for the next iteration, not a thing for the integrator to fix.

## How they compose

The loop, end-to-end:

1. **Plan in one session.** Customer writes stories. The planning agent (separate from the implementation agents) drafts ADRs as decisions surface. Each ADR is compressed before it lands. Stories get budget blocks; budget blocks reference the ADRs they depend on. Output: a small set of stories that can be implemented in parallel, each with a known ceiling under the smart-zone line.
2. **Fan out.** One worktree per parallel story. Each implementation session loads exactly the floor declared on its story card. No sibling diffs, no full repo scans.
3. **Implement in the smart zone.** Each slice is sized to finish before degradation. Tests first, runner-judged, atomic commit, reset. Same 12-point invariant list as [`xp-with-ai`](/docs/skills/xp-with-ai/#the-skill-a-one-page-invariant-list).
4. **Merge through the integrator.** Worktrees fold back in dependency order. The integrator runs the suite, posts diagnostics, logs actual token consumption against the estimates.
5. **Iterate.** Estimate-vs-actual deltas feed the next planning session. Bad ADR compression shows up as inflated floors across multiple stories. Optimistic working-budget multipliers show up as repeated dumb-zone warnings.

The whole thing is one loop turn of the existing XP cycle, with the *planning* and *integration* steps explicitly accounted for as context-economy events rather than free coordination.

## What this changes vs. single-agent XP

Most of `xp-with-ai`'s 12 invariants carry over unchanged. The ones that shift:

- **Stories before code** → stories before code, *with token budgets that bind*. A story without a budget block is a story you haven't finished planning.
- **Vertical slices** → vertical slices *that fit under a per-model ceiling*. The slicing criterion is now numerical, not vibes.
- **One slice, one PR** → one slice, one worktree, one PR. The worktree boundary makes the parallelism safe; the PR boundary makes it reviewable.
- **Reset, don't compact** → still true, and the integrator does it too. Especially the integrator. The merge step is where compaction is most tempting and most expensive.

What's added rather than modified:

- **ADRs are mandatory for cross-slice decisions.** Local decisions still stay local. But anything that binds another slice goes in an ADR, in compressed form, before the binding takes effect.
- **The tracker role is now quantitative.** Estimates in tokens, actuals in tokens, correction factor explicit. Beck's "the team learns its velocity over iterations" becomes literally a logged number per iteration.
- **The integrator is a named role with a narrow brief.** Not "the human in charge." A specific job with specific load limits.

## Failure modes specific to this variant

`xp-with-ai` already lists the failure modes the agent introduces. These are the new ones that show up when you start parallelizing:

- **ADR proliferation.** One ADR per micro-decision and you've reinvented the bloat you ran from. Discipline: ADRs only for decisions that *bind another slice*. Local choices stay local. If an ADR is referenced by exactly one story, it shouldn't be an ADR — it should be a comment.
- **Contract drift mid-implementation.** Halfway through a slice, an agent discovers the ADR doesn't quite hold. Now the parallel siblings are working from a stale contract. Cost: halt the cohort, replan, re-dispatch. Defense: keep ADRs *as compressed as they can be without being wrong* — over-specified contracts drift more.
- **Working-budget estimates wrong by 2–3×.** Inevitable for the first few iterations. Defense: log actuals from day one. The correction factor is a learned local truth, not a default.
- **Per-model budget confusion.** A story estimated for Sonnet, dispatched to Opus, exceeds the dumb-zone line. Defense: target model is a required field. The dispatcher refuses to start a session on a model the story wasn't budgeted for.
- **The integrator quietly becomes a coordinator.** Drift: the integrator starts reading diffs to "help arbitrate," then starts holding implementation opinions, then becomes the dumb-zone victim the design was supposed to prevent. Defense: the integrator's tools are restricted to merge, test, report. If it needs to read implementation code, the design has already failed somewhere upstream.

{: .tip }
> The single best diagnostic for whether this is working: pick any active worktree and ask "what's in its context right now, and is the answer close to the floor declared on its story card?" If the answer is *no, it's full of stuff that wasn't on the card*, the budget block is fiction and the loop will degrade into the same bloat it was supposed to prevent.

## What stays the same

Everything `xp-with-ai` says about the *human* boundaries is unchanged:

- The customer stays human. Scope, priority, and acceptance are not delegable.
- The agent does not own code. Every line is reviewed by a person before it lands.
- The test runner is the only judge. "Tests pass" without observed runner output means "tests not run."
- Refactor on demand, never on speculation. Especially not during a parallel cohort, where one agent's speculative refactor cascades into every sibling's context.

This page is about extending the loop, not loosening it.

## Related

- [XP with an AI on the team](/docs/skills/xp-with-ai/) — the single-agent variant this page extends
- [The XP workflow](/docs/skills/xp-workflow/) — the unmodified Beck source
- [The smart zone and the dumb zone](/docs/foundations/smart-zone-and-dumb-zone/) — the context-degradation finding that the per-story ceilings are sized against
- [Context is a budget, not a bucket](/docs/foundations/context-is-a-budget/) — the economic frame that token-counted velocity makes operational
- [Perception over history](/docs/foundations/perception-over-history/) — the working-memory move the integrator's "outcomes, not implementations" rule applies at the team level

## Sources

- Beck, K. (1999). *Extreme Programming Explained: Embrace Change.* Addison-Wesley.
- Nygard, M. (2011). *Documenting Architecture Decisions.* <https://cognitect.com/blog/2011/11/15/documenting-architecture-decisions> — the original ADR proposal this page compresses.
- Pocock, M. (2026). *Full Walkthrough: Workflow for AI Coding.* YouTube. <https://www.youtube.com/watch?v=-QFHIoCo-Ko> — for the smart-zone framing the per-story ceiling is sized against.

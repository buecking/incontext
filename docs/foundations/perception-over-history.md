---
title: Perception over history
layout: default
parent: Foundations
nav_order: 5
permalink: /docs/foundations/perception-over-history/
---

# Perception over history
{: .no_toc }

1. TOC
{:toc}

---

Every long-running agent session hits the same wall: the conversation grows faster than the model's attention scales, and somewhere past the sixty-thousandth token the agent starts forgetting what it was doing. The standard answer is to *compress the history* — KV-cache it, summarize it, retrieve from it. This page argues the standard answer is solving the wrong problem.

The agent doesn't need its history. It needs its **perception**: a current model of the task, the code, and what it's about to do. Humans don't navigate the world by replaying yesterday. We navigate by carrying a small, dense, continuously updated mental model. Agents should do the same.

What follows is a survey of how current systems compress context, an honest account of where each one breaks, and a design proposal — `perception.md` — for a compression layer that carries *state* instead of *trajectory*.

{: .note }
> Most of this page is empirical (the current-systems survey is sourced; the failure modes link out to citable evidence). The `perception.md` design proposal at the end is a contribution, not a literature review — clearly flagged where it crosses from "documented" into "designed."

## Why the standard answer is the wrong shape

The four common compression strategies in use today, with a short note on what each is and where it breaks. Cited evidence at the end of each section.

### Prompt caching (KV reuse)

**What it does.** The model provider stores the key-value tensors for a stable prefix of your context and reuses them on the next request. Anthropic, OpenAI, and Google all offer this. The savings are real: 75–90% reduction in input cost on multi-turn conversations is typical.

**How it works.** Exact byte-for-byte prefix match. If turn 5 changes a single character in turn 2, the cache is invalidated from turn 2 onward.

**Where it breaks.**

- **Edit fragility.** Any change to an earlier message kills the cache. Iterative refinement workflows (refactor → re-evaluate → refactor) get the worst of both worlds: long context, no caching.
- **Multi-breakpoint workarounds are limited.** Anthropic supports up to 4 cache breakpoints; some agents (Hermes is a good example — system + 3 rolling messages) burn all 4 just to keep a moving window cached. There's no semantic-level caching: caches reuse exact tokens, not exact meanings.
- **Cache TTL is short.** Anthropic's standard cache is 5 minutes; the 1-hour extended cache costs more per write. Idle sessions pay the full input cost on resume.

Prompt caching is a cost optimization, not a context-quality optimization. It does nothing about the dumb zone: a cached 200K context is the same dumb zone as an uncached 200K context.

### Summarization (compaction)

**What it does.** When context fills, run a separate model pass that produces a natural-language summary of earlier messages; replace the original messages with the summary. Claude Code's `/compact`, Cursor's summarization, and Hermes' four-phase compressor all work this way.

**How it works.** A subset of messages is rolled into a structured summary — typically with a fixed template (goal / progress / decisions / blockers / next steps). The compressor reserves a "head" (system prompt + first exchange) and a "tail" (most-recent N messages), summarizes the middle, and reassembles.

Hermes' approach is representative of the state of the art:

- Two compression layers — a gateway-level "session hygiene" at 85% of context, and an agent-loop compressor at 50%.
- Four phases — prune old tool results, determine boundaries (keeping tool_call/tool_result pairs intact), generate a structured summary via an auxiliary LLM, and reassemble.
- Iterative re-compression that *updates* the previous summary instead of regenerating, moving items from "in progress" to "done."

This is well-engineered and substantially better than naive truncation. It is still not enough.

**Where it breaks.**

- **Compaction rot.** Repeated summarization of summaries loses fidelity exponentially. By the third compaction, the agent is acting on a summary of a summary of a summary; specifics that mattered in turn 3 are footnotes in turn 50.
- **Format anchoring.** The summary template ("goal / progress / decisions") imposes a shape that may not match the task. Whatever doesn't fit the template gets dropped.
- **Decision drift.** The summary captures *what was decided* but not *why*. When a later situation invalidates the original reason, the agent keeps the decision and forgets the constraint.
- **No notion of currency.** The summary treats every fact as equal-weight. A decision made in turn 4 and superseded in turn 30 may survive both compactions because nothing flagged it as stale.
- **Tool-call orphaning.** Even with `_sanitize_tool_pairs()`-style logic, sub-conversations get mangled. The tool result that proved a hypothesis lives in the trash; the hypothesis remains as if proved.

The failure mode behind all of these is the same: **summarization preserves trajectory, not state.** It is an answer to "what happened" when the agent's question is "what's true."

See also: [the smart zone and the dumb zone](/docs/foundations/smart-zone-and-dumb-zone/), [failure modes §12](/docs/reference/failure-modes/#12-repetition-collapse).

### RAG (retrieve at generation time)

**What it does.** Index past content (or external documents) into a vector store; at each turn, retrieve the top-k chunks relevant to the current question and inject them into the prompt.

**Where it breaks.**

- **Cross-document reasoning is hard.** RAG works when the answer is *in* one of the top-k chunks. When the answer requires synthesizing across the top 50, retrieval gives you a shallow view.
- **Recency is not relevance.** Vector similarity has no notion of which version of a fact is current. The chunk that says "we use Postgres" and the chunk that says "we migrated to ScyllaDB" both score highly on a Postgres question. The model picks one — usually wrong.
- **Format-sensitive.** Liu et al.'s lost-in-the-middle finding ([arXiv:2307.03172](https://arxiv.org/abs/2307.03172)) hits hard here: middle chunks in a re-ranked list are systematically under-used.

RAG is the right tool when context is mostly external (a large codebase, a documentation corpus). It is a poor replacement for working memory.

### Sliding window

**What it does.** Keep the last N messages; throw out everything before that.

**Where it breaks.** Everywhere. The first time the agent needs to remember a decision from turn 4 in turn 25, the window has moved past it. Don't use sliding windows for anything that needs to remember anything.

## The shift: history vs perception

The shared failure mode across all four methods is treating the conversation as a **log to be compressed**. But the agent doesn't act on the log. It acts on its current model of the situation. The log is the input that produced the model. Once the model exists, the log is recoverable in principle and irrelevant in practice.

The same is true for humans. You don't remember most of yesterday. You remember *that the bug is in the parser*, *that the migration is paused on a legal review*, *that the next thing you need to do is call the on-call*. The journey from "I had no idea what was wrong" to "the bug is in the parser" is mostly gone. Only the conclusion survives.

Neuroscience has a name for this: [**memory consolidation**](https://en.wikipedia.org/wiki/Memory_consolidation). Episodic memories — what happened — are gradually transformed into semantic memories — what is true. The transformation is lossy by design. Holding the entire episodic record would be expensive and would compete for attention with the perception of *now*.

Reinforcement learning has a name for this: **belief state**. An agent in a partially-observable environment doesn't act on the trajectory; it acts on a posterior distribution over the world state, updated incrementally with each new observation. Trajectory is data; belief is the abstraction the agent reasons over.

The argument of this page is: **LLM agents should be given a belief state, not a trajectory.** That belief state is `perception.md`.

## The proposal: perception.md

{: .note }
> Everything from here forward is a design proposal. It draws on documented mechanisms (memory consolidation, world models, semantic compression) but the specific construct — a single perception.md file, the schema below, the layering — is not, as of writing, a deployed system. Treat as a contribution to think with, not a survey.

### One file, continuously updated

`perception.md` is a file the agent maintains alongside the codebase. Its sole job is to represent **what the agent currently believes to be true** about its task. Not what happened. Not the transcript. The model.

Roughly: if you destroyed the session history and gave a fresh agent only `perception.md`, it should be able to pick up exactly where the previous agent left off without re-explaining anything.

That is a stronger claim than "summary that's enough to keep going." A good `perception.md` makes the *history irrelevant*.

### Three layers

Not all perception decays at the same rate. The file is structured into three layers, each updated on its own cadence:

- **Invariants** — facts that are true for the whole task and probably the whole project. The stack, the conventions, the constraints. Updated rarely; behave like CLAUDE.md.
- **Frame** — facts that are true for the current feature / slice / PR. The story, the acceptance criteria, the open questions, the decisions made so far. Updated at the start of every slice; survives across a few sessions.
- **Working set** — facts that are true for the next few minutes. The file you're editing, the hypothesis you're testing, the next thing to do. Updated continuously; overwritten as often as needed.

The token-cost economics fall out of the layering: invariants are stable and cache well; the frame is medium-stability and cache-friendly when the slice is small; the working set is volatile and shouldn't be cached. Three cache breakpoints, one per layer, fits cleanly into Anthropic's four-breakpoint limit with one to spare.

### The schema

The file is markdown, but the content is closer to a structured belief log than to prose. The goal is dense, machine-friendly, human-auditable. Below is a concrete schema. Adapt freely.

```markdown
# perception.md

## Invariants
- stack: TypeScript / Bun / Postgres 16
- test-runner: bun test (`just test`)
- style: see .claude/rules/style.md
- forbidden: writes to ./vendor/, edits to migrations < 0042

## Frame
slice: 023-points-on-lesson-completion
story: "When a user completes a lesson, they earn N points visible on the dashboard."
acceptance:
  - one schema column added to lessons.points
  - one service method awardPoints(userId, lessonId)
  - one API endpoint POST /lessons/:id/complete
  - one UI element rendering the running total
decided:
  - points are integer, not float [reason: legal, no fractional currency]
  - award is idempotent per (user, lesson) [reason: replay safety]
open:
  - does the bonus multiplier apply here? [blocked on product]
constraints:
  - cannot ship before 2026-05-20 (legal freeze ends)

## Working set
file: src/services/points.ts
hypothesis: idempotency belongs in the service, not the schema
next:
  1. failing test for double-award
  2. minimal implementation
  3. refactor extract awardOrSkip helper
recent-tool-results:
  - bun test points.spec.ts → 1 failed (idempotency), 4 passed
  - rg "awardPoints" → 0 callers yet
```

That whole file is around 250 tokens. Compare to the equivalent transcript of how the agent got there, which is easily 20–50× longer. The compression ratio is not the point — the *fidelity at the compressed size* is. A summary that fits the same token budget would have lost half the structure.

### The "gibberish language" angle

The schema above uses human-readable prose. A more aggressive version uses a denser notation — designed for the model's parser, not for human skim-reading. Something like:

```
inv{stack:ts/bun/pg16; tests:`bun test`; style:.claude/rules/style.md; nogo:./vendor/,mig<0042}
frame{slice:023; goal:"points on completion"; ac:[col,svc,api,ui];
      decided:[int(legal),idempotent(replay)];
      open:[bonus-mult?@product];
      freeze:>=2026-05-20}
work{file:points.ts; hyp:idempotency@service;
     next:[fail-test:double-award→impl→refactor:awardOrSkip];
     last:[test:1F/4P,rg:0callers]}
```

This is the "gibberish" — not actually gibberish, but a compressed notation that LLMs parse reliably (they parse far less natural formats every day) and that hits roughly half the tokens of the prose schema for the same content.

Whether this is worth the readability cost is task-dependent. For ephemeral working-set content, yes. For invariants that humans review in PRs, no — keep those readable.

### Why this is faster than summarization

Three reasons, in increasing order of importance:

1. **No replay.** A summary still narrates *what was done*. A perception file says *what is*. State is bounded; trajectory grows monotonically. Past a certain task complexity, even the best summarizer is summarizing *more* than the perception needs to contain.

2. **Stable cache.** Perception layers are touched on predictable schedules: invariants almost never, frame per-slice, working set per-action. The invariant + frame prefix caches well across many turns. Summaries get rewritten on every compaction; their cache lifetime is one turn.

3. **No compaction rot.** Each update to `perception.md` writes a fresh belief state, not a summary of a summary. The lossiness happens once at write-time (when the agent encodes its current model into the file), not iteratively.

The fourth reason, which is harder to measure but probably the largest in practice: **the file is auditable.** When the agent is doing the wrong thing, you can `cat perception.md` and see what it believes. Debugging a confused agent today means scrolling a transcript. Debugging it with perception means reading one short file.

## What this isn't

Several things this proposal is *not*:

- **Not a replacement for `CLAUDE.md`.** Invariants live in both; `perception.md` is dynamic. `CLAUDE.md` is the static seed; `perception.md` is the running belief.
- **Not a replacement for prompt caching.** Layered perception *plays well* with KV caching — the layering is designed for it.
- **Not a replacement for the full session log when debugging.** Logs still exist. They are just not the agent's working memory.
- **Not magic.** A bad perception encoding produces bad results, the same way a bad summary does. The win comes from the right *shape* (state, not trajectory), not from any specific format.

## Open questions

This is a design, not a deployed system. Honest gaps:

- **Who writes the working set?** The agent itself, on every turn? An external compressor? A hook that fires on every action? Different choices have different cache implications.
- **How does the agent know the perception is stale?** Some signal that the file no longer matches reality — a test failure, a contradicted assumption, a tool result that doesn't fit. Worth designing explicitly.
- **What about multi-agent setups?** When two agents share a task, do they share perception? The plural form is interesting — `perception.md` as the durable common ground that survives both agents resetting.
- **Compression ratio in the limit.** How dense can the encoding get before the model can't read it reliably? Probably testable; not yet tested.
- **Failure mode: the agent stops trusting its perception.** If the file disagrees with the code, which does the agent believe? Defaults to "code wins on conflict" feel right, but the consequences need working out.

A serious empirical evaluation would look like: take a long-running coding task; compare an agent run with standard `/compact` against an agent run with hand-maintained `perception.md`; measure task success, token cost, and time-to-completion. That experiment hasn't been run as of writing.

## How to try this today

You don't need any custom infrastructure to start using `perception.md`. The two-line version:

1. Add `perception.md` to your repo (gitignored or committed, your call).
2. In `CLAUDE.md`, instruct the agent: *"Maintain `perception.md` as the running model of the current task. At the start of every slice, write the frame. After each action, update the working set. Before reading the chat history for context, read this file first."*

That gets you most of the benefit on Claude Code today. The agent will treat the file as a load-bearing artifact, and you can shape what it writes by editing the file directly when it gets it wrong.

A more ambitious version would expose the layering to the harness: distinct cache breakpoints per layer, automatic perception updates on tool-result events, a `/perception` slash command that pretty-prints the current state. None of that is necessary to start.

## Related

- [Context is a budget, not a bucket](/docs/foundations/context-is-a-budget/) — the underlying economics
- [The smart zone and the dumb zone](/docs/foundations/smart-zone-and-dumb-zone/) — why finishing in the smart zone matters
- [Long-context degradation](/docs/foundations/long-context-degradation/) — the empirical case for less context, not more
- [Failure modes](/docs/reference/failure-modes/) — what goes wrong with current compression strategies

## Sources

- Hermes Agent, *Context Compression and Caching* developer guide: <https://hermes-agent.nousresearch.com/docs/developer-guide/context-compression-and-caching>
- Anthropic, *Prompt Caching*: <https://docs.anthropic.com/en/docs/build-with-claude/prompt-caching>
- Liu et al. 2023, *Lost in the Middle: How Language Models Use Long Contexts*, [arXiv:2307.03172](https://arxiv.org/abs/2307.03172)
- Modarressi et al. 2025, *NoLiMa: Long-Context Evaluation Beyond Literal Matching*, [arXiv:2502.05167](https://arxiv.org/abs/2502.05167)
- Hsieh et al. 2024, *RULER: What's the Real Context Size of Your Long-Context Language Models?*, [arXiv:2404.06654](https://arxiv.org/abs/2404.06654)
- Xiao et al. 2024, *Efficient Streaming Language Models with Attention Sinks*, [arXiv:2309.17453](https://arxiv.org/abs/2309.17453)
- Anthropic, *Effective Context Engineering for AI Agents*: <https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents>
- Wikipedia, *Memory consolidation*: <https://en.wikipedia.org/wiki/Memory_consolidation>
- Kaelbling, Littman & Cassandra 1998, *Planning and acting in partially observable stochastic domains* — the canonical belief-state reference in RL.

---
title: Context is a budget, not a bucket
layout: default
parent: Foundations
nav_order: 2
permalink: /docs/foundations/context-is-a-budget/
---

# Context is a budget, not a bucket
{: .no_toc }

1. TOC
{:toc}

---

The first thing people notice about modern models is that the context window has gotten huge. Two hundred thousand tokens. A million. The natural reaction is: stop curating, just dump everything in. Let the model figure out what matters.

This is wrong, and it's wrong in a way that matters more the bigger the window gets.

## What a context window actually is

A context window is a budget, not a bucket. Every token you add does three things:

1. **Costs money and latency.** Linear in tokens, sometimes worse. Even with prompt caching, the first time a long prefix lands you pay for every token.
2. **Competes for attention with every other token.** The model's attention is a finite resource being divided across what you put in front of it. Adding irrelevant material doesn't sit politely in a corner — it pulls attention away from the relevant material.
3. **Adds opportunities for confusion.** Every additional document is another chance for the model to anchor on the wrong thing, follow a stale instruction, or pattern-match to the wrong example.

The naive "just dump it all in" intuition treats context like RAM — neutral storage that the model queries. It's not. Context is more like a meeting agenda. A meeting with twelve agenda items isn't twice as productive as one with six. It's usually less productive, because attention fragments and the important items get rushed.

## The empirical case

This isn't a stylistic preference. The published evidence on long-context degradation is now consistent across three lines of research:

- **Lost in the middle.** Liu et al. 2023 ([arXiv:2307.03172](https://arxiv.org/abs/2307.03172)) showed that information placed mid-context is used worse than the same information at the start or end. The accuracy curve is U-shaped over position. On GPT-3.5-Turbo, retrieval accuracy dropped from ~75% (first position) to ~52% (middle). See [long-context degradation](/docs/foundations/long-context-degradation/).
- **Effective vs. nominal window.** RULER (Hsieh et al. 2024, [arXiv:2404.06654](https://arxiv.org/abs/2404.06654)) measured the effective context length of long-context models against their advertised window. Most fall well short of their nameplate spec under any threshold that requires actual reasoning rather than retrieval.
- **Reasoning collapse past ~32k.** NoLiMa (Modarressi et al. 2025, [arXiv:2502.05167](https://arxiv.org/abs/2502.05167)) re-ran the lost-in-the-middle eval with one-hop reasoning required. Frontier models with 128k–1M nominal windows lose **50%+ of short-context accuracy by ~32k tokens**.

Anthropic's own *Effective Context Engineering for AI Agents* (September 2025) names the phenomenon "context rot" and frames context as a "finite resource with diminishing marginal returns." The guidance from the people training the models is unambiguous: curate.

## What this means in practice

A few rules of thumb that fall out of the budget framing:

- **Cut before you add.** Default to less. The question isn't *could this be useful?* but *is this load-bearing for the task at hand?*
- **Order matters.** Models attend more strongly to the start and end of context. Put the instruction at the top, the critical reference material near the bottom, and the bulk in the middle where it can be skimmed.
- **Repetition is a tool, not a smell.** If something is genuinely critical, restating it at the end is cheap insurance. See [directives §9 — bookending](/docs/reference/directives/#9-bookending--top-and-end-of-long-context).
- **A clean 8K context usually beats a messy 80K one.** Counterintuitive until you've measured it. Once you have, it's the most useful rule on this list.

That last one surprises people most and is the most worth internalizing. The shift from "engineering prompts" to "engineering context" is real, but the underlying skill is the same: figure out what the model needs, give it that, and stop.

## Where the budget goes

Looking at a typical Claude Code session before any user input, the *baseline* context the model is already paying for:

- **System prompt** — a few thousand tokens, baked into the harness.
- **Tool definitions** — every tool the harness exposes is described in context. Easily 5–10k tokens for an agent with MCP servers.
- **`CLAUDE.md` and imports** — anything from a few hundred to several thousand tokens, depending on how disciplined the file is.
- **Loaded skills' descriptions** — every skill's `description` field sits in context so the agent knows what's available. A workspace with 20 skills can be a couple thousand tokens before the agent has done anything.
- **File reads from the harness** — `git status`, `ls`, opened-file contents that the harness auto-injects.

The "user task" — the thing you're actually asking the agent to do — is often less than 5% of the context that's already in front of the model when it answers. Most of the budget is spent on the *frame*, not the *question*. Which means: editing the frame is where most of the leverage is.

## How to measure if you're over budget

Three diagnostics, in increasing order of effort:

1. **The same task in a fresh session vs. a long one.** If the model handles a task correctly at the start of a session and badly after 30k tokens of accumulated history, the long session is over budget. (This is also the [smart zone / dumb zone](/docs/foundations/smart-zone-and-dumb-zone/) signal.)
2. **Strip and re-run.** Remove a section of your `CLAUDE.md`, or unload a skill, and rerun the task. If output quality doesn't change, that content wasn't earning its place. If quality drops, it was. Most teams discover that more than half their `CLAUDE.md` falls in the first category.
3. **Position swap.** Put your most important instruction at the bottom of the prompt and rerun. If the model follows it now but didn't before, it was being [lost in the middle](/docs/foundations/long-context-degradation/) — and the budget had room for it, just not at that position.

The strip-and-re-run test is the most honest. It's also the most uncomfortable, because most teams have written more context than they need and don't want to find out.

## Common ways the budget gets blown

The patterns repeat across teams:

- **Pasting reference material instead of citing it.** A 5,000-line architecture overview embedded in `CLAUDE.md` is paying full rent on every session. Cite it with `@docs/architecture.md` and the import system loads it on demand. See [cite, don't summarize](/docs/patterns/cite-dont-summarize/).
- **Aspirational rules.** Conventions the team wishes it followed, written into the context resource as if they were true. The agent now writes against a fiction. See [aspirational rules](/docs/reference/failure-modes/#5-aspirational-rules).
- **Stale instructions.** Commands and paths that used to be true and aren't anymore. The agent weights the explicit imperative over live evidence and "fights" the code. See [stale instructions](/docs/reference/failure-modes/#3-stale-instructions).
- **The wall of don'ts.** A `CLAUDE.md` made of fifty negative instructions, each of which adds a forbidden-noun token without giving the agent a positive direction. See [negative examples](/docs/patterns/negative-examples/).
- **One file for everything.** Frontend rules and backend rules in the same `CLAUDE.md`, both loaded on every task, each pulling attention from the other. See [scope by directory](/docs/patterns/scope-by-directory/).

If you find yourself blown over budget, the fix is usually structural, not editorial. Splitting one big file into directory-scoped files, or moving content into [skills](/docs/skills/) that load on demand, recovers more budget than any amount of word-trimming.

{: .tip }
> When you're tempted to add another document to the context, ask: would I add a fifteenth slide to a ten-slide deck for the same reason? Usually the answer is no.

## The deeper frame

The budget framing is the gateway to the rest of this site. Once you've internalized that context is finite and contested rather than abundant and neutral, the other ideas follow:

- **Layering** ([layered context](/docs/patterns/layered-context/)) is how you spend the budget on the most-relevant material first.
- **Scope** ([scope by directory](/docs/patterns/scope-by-directory/)) is how you make rules pay rent only when they're relevant.
- **Perception** ([perception over history](/docs/foundations/perception-over-history/)) is how you replace expensive trajectory with cheap belief state.
- **The smart zone** ([smart-zone framing](/docs/foundations/smart-zone-and-dumb-zone/)) is the operating stance for staying under budget across a working session.

The patterns differ in form. They all answer the same question: *given that context is a budget, how do I spend it?*

## Related

- [Long-context degradation](/docs/foundations/long-context-degradation/) — the empirical "lost in the middle" finding
- [The smart zone and the dumb zone](/docs/foundations/smart-zone-and-dumb-zone/) — the working stance that falls out of the budget
- [Layered context](/docs/patterns/layered-context/) — how to spend the budget by scope and cadence
- [Failure modes §2 — context bloat](/docs/reference/failure-modes/#2-context-bloat--token-budget-exhaustion) — what budget exhaustion looks like in practice
- [Directives §1 — specificity beats qualifier words](/docs/reference/directives/#1-specificity-beats-qualifier-words) — getting more behavior change per token

## Sources

- Liu, N. F., et al. (2023). *Lost in the Middle.* [arXiv:2307.03172](https://arxiv.org/abs/2307.03172).
- Hsieh, C.-P., et al. (2024). *RULER: What's the Real Context Size of Your Long-Context Language Models?* [arXiv:2404.06654](https://arxiv.org/abs/2404.06654).
- Modarressi, A., et al. (2025). *NoLiMa: Long-Context Evaluation Beyond Literal Matching.* [arXiv:2502.05167](https://arxiv.org/abs/2502.05167).
- Anthropic (2025). *Effective Context Engineering for AI Agents.* <https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents>.

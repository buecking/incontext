---
layout: default
title: Context is a budget, not a bucket
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

1. **Costs money and latency.** Linear in tokens, sometimes worse.
2. **Competes for attention with every other token.** The model's attention is a finite resource being divided across what you put in front of it. Adding irrelevant material doesn't sit politely in a corner — it pulls attention away from the relevant material.
3. **Adds opportunities for confusion.** Every additional document is another chance for the model to anchor on the wrong thing, follow a stale instruction, or pattern-match to the wrong example.

The naive "just dump it all in" intuition treats context like RAM — neutral storage that the model queries. It's not. Context is more like a meeting agenda. A meeting with twelve agenda items isn't twice as productive as one with six. It's usually less productive, because attention fragments and the important items get rushed.

## What this means in practice

- **Cut before you add.** Default to less. The question isn't "could this be useful?" but "is this load-bearing for the task at hand?"
- **Order matters.** Models attend more strongly to the start and end of context. Put the instruction at the top, the critical reference material near the bottom, and the bulk in the middle where it can be skimmed.
- **Repetition is a tool, not a smell.** If something is genuinely critical, restating it at the end is cheap insurance.
- **A clean 8K context usually beats a messy 80K one.**

This last rule surprises people most and is the most worth internalizing. The shift from "engineering prompts" to "engineering context" is real, but the underlying skill is the same: figure out what the model needs, give it that, and stop.

{: .tip }
> When you're tempted to add another document to the context, ask: would I add a fifteenth slide to a ten-slide deck for the same reason? Usually the answer is no.

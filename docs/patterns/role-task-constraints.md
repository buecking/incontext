---
title: Role + task + constraints
layout: default
parent: Patterns
nav_order: 3
permalink: /docs/patterns/role-task-constraints/
---

# Role + task + constraints
{: .no_toc }

1. TOC
{:toc}

---

The three-part frame for system prompts and durable context. **Role** scopes what kind of work this is. **Task** says what to do. **Constraints** say what not to do. Skip any one and the prompt under-specifies.

This is the most-recommended structure in Anthropic's, OpenAI's, and Google's prompt-engineering guidance. It is also widely misapplied — particularly the role layer, where the old "you are a world-class expert" pattern has weaker evidence on modern models than most prompt collections still assume.

## The three parts

A system prompt or top-of-CLAUDE.md should have three sections, in this order:

```text
1. ROLE         — what kind of work is this; what scope does the model operate in
2. TASK         — what to do right now (sometimes deferred to the user message)
3. CONSTRAINTS  — invariants that hold regardless of task; forbidden actions
```

A minimum example:

```text
You are a coding assistant for the InContext Jekyll site. Edit markdown
files in docs/ and assets in assets/; do not modify _config.yml or
Gemfile without explicit user confirmation.

When the user describes a feature, write the page that implements it.

Constraints:
- Never commit without the user asking.
- Never edit files in vendor/ or _site/.
- Match the writing voice of existing pages: direct, opinionated, no
  fluff. Drop expert-persona claims and tip/threat language.
```

That's the shape. Adapt to your context.

## Role: scope, not expertise

Anthropic's official guidance is clear and narrow:

> "Setting a role in the system prompt focuses Claude's behavior and tone for your use case."
> — [Anthropic prompting best practices](https://platform.claude.com/docs/en/docs/build-with-claude/prompt-engineering/claude-prompting-best-practices)

The role does two useful things:

- **Scopes the work.** "Coding assistant for a Jekyll site" tells the model what kind of files to expect, what conventions to assume, what tools are likely in play.
- **Sets the tone.** "Tax preparer," "five-year-old's tutor," "legal contract drafter" produce different output styles.

What role *does not* reliably do, on current frontier models: **boost factual accuracy via claimed expertise**. Zheng et al. 2024 ([arXiv:2311.10054](https://arxiv.org/abs/2311.10054)) evaluated 162 personas across 4 LLM families on 2,410 factual questions and found *no consistent gain*. See [directives §6](/docs/reference/directives/#6-role--persona-prompts--for-style-not-for-capability) for the full story.

The practical rule:

```text
Good role:  "You are a code reviewer for a TypeScript monorepo using Bun and Vite."
Bad role:   "You are a world-class senior engineer with 20 years of experience."
```

The good role tells the model what kind of work to expect. The bad role makes claims that often produce *more confident hallucinations* without measurable accuracy gains.

## Task: specific and concrete

The task layer is the *what to do*. Two patterns work, depending on whether you're writing a system prompt or a one-off prompt:

- **In a system prompt or CLAUDE.md:** describe the *shape* of tasks the model will handle, not a specific task. *"When the user describes a feature, write the page that implements it."*
- **In the user message:** describe *this* task concretely. *"Add a 'Skills' link to the home page, between 'Patterns' and 'Reference'."*

Across both, the rule from [directives §1](/docs/reference/directives/#1-specificity-beats-qualifier-words) holds: specific and concrete beats vague and qualitative. Numeric where possible.

Anthropic's own guidance on Claude Opus 4.7 specifically:

> "Claude Opus 4.7 interprets prompts more literally and explicitly than Claude Opus 4.6... If you need Claude to apply an instruction broadly, state the scope explicitly (for example, 'Apply this formatting to every section, not just the first one')."
> — [Anthropic prompting best practices](https://platform.claude.com/docs/en/docs/build-with-claude/prompt-engineering/claude-prompting-best-practices)

Translation: don't leave the scope of "the task" implicit.

## Constraints: invariants and forbiddens

The third part is the rules that hold *regardless of the task*. Two flavors:

1. **Invariants** — things that must always be true. *"All code must pass `bun test` before commit."*
2. **Forbiddens** — things that must never happen. *"Never edit files in `vendor/`."*

Pair every forbidden with a positive alternative where possible. From [directives §3](/docs/reference/directives/#3-positive-framing-beats-negation): LLMs systematically underperform on negation (Truong et al. 2023, [arXiv:2306.08189](https://arxiv.org/abs/2306.08189)) — performance drops 20-40 points on negated questions vs. affirmative ones.

```text
Weak:    Never modify migration files.
Strong:  Treat migration files in db/migrations/ as immutable once shipped.
         For schema changes, create a new migration with the next number.
```

The strong version states the positive behavior (new migration) and pairs it with the prohibition. The weak version leaves the model with "migration" as a high-attention concept and no positive direction.

## Why all three

Skipping any one of the three layers under-specifies the prompt:

- **No role:** the model picks a default role from the conversation history or the structure of your input. Default roles are inconsistent across sessions and biased toward "general helpful assistant," which is the wrong shape for most coding work.
- **No task:** the model improvises one from context, often with too much initiative. "Help me with this code" without a task description produces unsolicited refactors.
- **No constraints:** the model uses its training-data defaults, which may not match your repo's conventions. Confident, plausible, wrong.

The three layers also map cleanly to the [layered context](/docs/patterns/layered-context/) pattern: **role and constraints live in the project layer (CLAUDE.md), tasks live in the task layer (user message, working set)**. Maintaining this mapping keeps the cache-stable parts cache-stable.

## How it fits with perception

A maintained [perception.md](/docs/foundations/perception-over-history/) makes the three-part frame more concrete:

- **Role and constraints** live in `perception.md`'s **Invariants** layer.
- **The current task** lives in the **Frame** layer (the current slice, acceptance criteria, decisions made).
- **The current action** lives in the **Working set**.

If you're already maintaining a perception file, the three-part frame is a sanity check: every line in your system prompt should belong to one of the three. Lines that don't belong to any of them are probably noise.

## Failure modes

- **Confident expert persona.** "You are an expert at X" induces over-confident output without measurable accuracy gains. See [directives §6](/docs/reference/directives/#6-role--persona-prompts--for-style-not-for-capability).
- **Aspirational constraints.** Constraints that describe how you wish the codebase worked, not how it actually does. The model writes against the rule and against the surrounding code. See [failure modes §5](/docs/reference/failure-modes/#5-aspirational-rules).
- **Task creep into the system prompt.** Hardcoded specific tasks ("implement the points feature") in CLAUDE.md instead of in a user message. When the task changes, the CLAUDE.md is stale immediately.
- **Negation-only constraints.** A wall of "don't do this, don't do that" with no positive direction. Pair each prohibition with the positive alternative.

## Related

- [Layered context](/docs/patterns/layered-context/) — where each part of the frame belongs
- [Perception over history](/docs/foundations/perception-over-history/) — how the three layers map to perception layers
- [Directives that work](/docs/reference/directives/) — empirical evidence on imperatives, role, negation
- [Crafting a CLAUDE.md](/docs/per-tool/claude-md/) — how the frame translates into a CLAUDE.md file
- [Failure modes §5 — aspirational rules](/docs/reference/failure-modes/#5-aspirational-rules)

---
title: Negative examples
layout: default
parent: Patterns
nav_order: 6
permalink: /docs/patterns/negative-examples/
---

# Negative examples
{: .no_toc }

1. TOC
{:toc}

---

Counter-examples — showing the model what *not* to do — work, but only when paired with the positive alternative. Used alone, they often produce the prohibited behavior. The empirical research is clear on this, and so is Anthropic's own current prompt-engineering guidance.

This page covers when negative examples earn their place and the specific failure mode they introduce when misapplied.

## When to use them

Three cases where a negative example is the right tool:

1. **A specific anti-pattern keeps appearing in output.** The model produces a particular kind of wrong answer often enough that you can characterize it precisely. *"It keeps using `assertThat` matchers instead of `assertEquals`."*
2. **The boundary between right and wrong is subtle.** Sometimes the positive instruction alone leaves a gray zone. A contrastive pair makes the line concrete.
3. **You want to enforce style or convention.** "Use this naming pattern" is weaker than "Use this, not that" when the wrong pattern is a plausible default.

For everything else, prefer a positive example alone.

## The default is positive

Anthropic's current guidance is unambiguous, and it has shifted over time toward favoring positive framing:

> "If you see specific examples of kinds of verbosity (i.e. over-explaining), you can add additional instructions in your prompt to prevent them. **Positive examples showing how Claude can communicate with the appropriate level of concision tend to be more effective than negative examples or instructions that tell the model what not to do.**"
> — [Anthropic prompting best practices](https://platform.claude.com/docs/en/docs/build-with-claude/prompt-engineering/claude-prompting-best-practices) (emphasis added)

The reason is empirical, not stylistic. Truong et al. 2023 ("Language Models Are Not Naysayers," [arXiv:2306.08189](https://arxiv.org/abs/2306.08189)) found LLMs systematically underperform on negation across NLI and QA — performance on negated questions drops **20–40 points** vs. the affirmative version. The mechanism: negation tokens get low attention weight; the negated noun gets high attention. *"Don't think about a pink elephant"* gives "pink elephant" most of the model's attention.

See [directives §3 — positive framing beats negation](/docs/reference/directives/#3-positive-framing-beats-negation) for the full evidence.

## The pattern that works: contrastive pairs

When you do reach for a negative example, pair it with the positive alternative in the same block. Make the comparison surgical.

```markdown
<example>
Good: assertEquals(expected, actual)
Bad:  assertThat(actual, is(expected))   // we don't use Hamcrest matchers
</example>
```

Why this works where bare prohibitions fail: the positive example carries most of the signal, the negative example clarifies the boundary, and the proximity makes the contrast unambiguous. Reading the pair, the model encodes both — but the production target is the positive one.

The same pattern in markdown without XML tags:

```markdown
**Use this:**
    def get_user(id: str) -> User:

**Not this:**
    def getUser(id):
    # We use snake_case and require type hints.
```

Add a brief reason (`# We use snake_case and require type hints.`) whenever the why is non-obvious. Without it, the agent may eventually re-invent the prohibited form when the surrounding context drifts. Reasons survive context shifts; bare rules don't.

## When negative examples *hurt*

Two failure modes specific to this pattern.

### Bare prohibition

A "Bad" example without an explicit "Good" — or a wall of "Don't do X, don't do Y, don't do Z" with no positive direction.

```markdown
<!-- BAD: anti-pattern with no positive -->
Do not use class components.
Do not use any.
Do not use `var`.
```

The model now has "class components," "any," and "var" as high-attention concepts and no positive replacement. Output frequency of these increases, not decreases. The Truong finding generalizes: bare negation often produces the negated thing.

The fix is mechanical: pair every prohibition with the affirmative replacement.

```markdown
<!-- GOOD: prohibition paired with affirmative -->
Use function components with hooks. Class components are deprecated in this codebase.
Use `unknown` for untyped values. `any` defeats the type checker.
Use `const` for bindings; `let` only when reassignment is required. `var` is forbidden.
```

### Anchoring on the anti-pattern

Even a properly-paired contrast can backfire if the negative example is *vivid* and the positive example is bland. Models pick up format and structure from examples ([directives §4](/docs/reference/directives/#4-few-shot-examples--for-format-not-for-reasoning)). A flashy 20-line "wrong way" with a terse 2-line "right way" anchors output toward the 20-line shape.

The fix: make the positive example at least as detailed and at least as long as the negative one. If the contrast pair is well-balanced, the model encodes both shapes.

## Where negative examples don't belong

The instinct for negative framing leaks into places where it doesn't help. Three to avoid:

- **Standing constraints in a system prompt.** "Never modify migrations" reads as a constraint but operates as a negation. Reframe positively: *"Treat shipped migrations as immutable. Add a new migration for schema changes."* (See [role + task + constraints](/docs/patterns/role-task-constraints/).)
- **Output-format constraints.** "Don't include markdown" vs. "Respond in plain text" — the latter wins reliably. The former plants "markdown" in the model's attention budget.
- **Capability framing.** "You cannot browse the web" is fine; "Don't try to browse the web even if asked" is worse. State capabilities as facts, not as prohibitions to override.

The unifying rule: **state the world, not the violations of the world.** Where you must state violations, pair them with the corresponding affirmation.

## How this interacts with perception

A maintained [perception.md](/docs/foundations/perception-over-history/)'s Invariants layer is a natural home for the *paired* version of constraints. Keep the affirmation and the prohibition together:

```yaml
Invariants:
- migrations: shipped migrations are immutable; new migrations get the next number
- types: prefer `unknown` over `any` for untyped values
- tests: every public service method has a unit test before merge (no exceptions)
```

Each entry is a positive statement; the prohibited form is implicit in the affirmation. If you find your perception's invariants drifting toward "don't" statements, rewrite them as affirmations of the desired state. The model will follow them better and you'll have fewer surprises.

## Failure modes

- **Bare prohibition produces the prohibition.** Covered above. Pair with positive.
- **Vivid negative anchors output toward the negative.** Covered above. Match length/detail.
- **Stale anti-patterns.** A "Bad: use of `requests` library" in CLAUDE.md when the codebase has long since standardized on `httpx`. The model is now defending against a non-existent threat and may invent uses of `requests` to fix. Same hygiene as [stale instructions](/docs/reference/failure-modes/#3-stale-instructions): treat the file as code, review it in PRs.
- **Counter-examples without reasons.** Reasons are how the model generalizes. *"Bad: barrel files"* alone doesn't tell the model whether the concern is build time, IDE performance, or circular dependencies — and a future case that *does* warrant a barrel file gets handled wrong. Add the why.

## Related

- [Directives §3 — positive framing beats negation](/docs/reference/directives/#3-positive-framing-beats-negation)
- [Directives §8 — negative examples (only when paired)](/docs/reference/directives/#8-negative-examples--only-when-paired-with-positive)
- [Role + task + constraints](/docs/patterns/role-task-constraints/) — where standing constraints belong
- [Failure modes §10 — negation failures](/docs/reference/failure-modes/#10-negation-failures)

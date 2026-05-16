---
title: CRAFT framework (review)
layout: default
parent: Patterns
nav_order: 99
permalink: /docs/patterns/craft-framework/
---

# CRAFT framework (review)
{: .no_toc }

1. TOC
{:toc}

---

CRAFT is a seven-letter mnemonic for writing one-shot prompts, popularized by Alexander F. Young: **C**ontext, **R**equest, **A**ctions, **F**rame, **T**emplate, plus optional **E**xample and **D**evelop ([source](https://blog.alexanderfyoung.com/how-to-craft-the-perfect-prompt/)). It belongs to a wider genre of consumer-facing prompt acronyms — COSTAR, RACE, RISEN, CLEAR — that all wrap roughly the same primitives.

This page reviews CRAFT against the evidence the rest of this site is built on. The short version: the *behaviours* CRAFT asks you to perform (be specific, give a format, show examples) are individually well-supported. The *wrapper* is a memory aid. CRAFT's weakest letter is its first — Context-as-Persona — which leans on a pattern the published evidence doesn't support.

## The seven letters, as stated

Faithful summary of Young's post, no editorialising:

- **C — Context.** Adopt a persona, character, or role. Specify tone and audience. Young uses a sub-mnemonic *PAT* (Persona / Audience / Tone) and gives examples like *"You are a children's book writer writing for children aged 10–18 in the style of JK Rowling."*
- **R — Request.** A single clearly defined task or goal.
- **A — Actions.** A numbered list of instructions or steps to complete the request.
- **F — Frame.** Constraints: what to include, what to exclude. E.g. *"Only respond with the chapters. Do not include any other text."*
- **T — Template.** Output format — bullet list, table, code block, headings.
- **E — Example.** *(Optional)* Few-shot demonstrations of the desired output shape.
- **D — Develop.** *(Optional)* Iterate on the prompt and the response.

## Annotated against the evidence

| CRAFT letter | Maps to (this site) | Evidence verdict |
|---|---|---|
| **C — Context** (Role / Persona / PAT) | [Role + task + constraints §Role](/docs/patterns/role-task-constraints/#role-scope-not-expertise) | **Partial.** Role as *scope* and *tone* is supported. Persona-as-expertise gives no consistent accuracy gain (Zheng 2024) — see [directives §6](/docs/reference/directives/#6-role--persona-prompts--for-style-not-for-capability) for the full study and citation. |
| **R — Request** | [Task](/docs/patterns/role-task-constraints/#task-specific-and-concrete) · [Directives §1](/docs/reference/directives/#1-specificity-beats-qualifier-words) | **Supported.** Specificity is the single most reliable lever — prompt-format variation alone swings accuracy by up to 76 pp on LLaMA-2-13B classification (Sclar et al. 2023, [arXiv:2310.11324](https://arxiv.org/abs/2310.11324)). |
| **A — Actions** | [Directives §1](/docs/reference/directives/#1-specificity-beats-qualifier-words) · [§2](/docs/reference/directives/#2-bare-imperatives-second-person) | **Supported.** A numbered step list is a specificity device. Prefer bare imperatives ("indent with tabs") over softened ones ("you should indent with tabs"). |
| **F — Frame** (constraints) | [Constraints](/docs/patterns/role-task-constraints/#constraints-invariants-and-forbiddens) · [Directives §3](/docs/reference/directives/#3-positive-framing-beats-negation) | **Partial.** Constraints are supported. Young's examples lean heavily on negation — *"do not include any other text"* — and models systematically underperform on negation by 20–40 pp vs. affirmative phrasing (Truong et al. 2023, [arXiv:2306.08189](https://arxiv.org/abs/2306.08189)). Pair every prohibition with the positive alternative. |
| **T — Template** (format) | [Directives §4](/docs/reference/directives/#4-few-shot-examples--for-format-not-for-reasoning) · [§7](/docs/reference/directives/#7-format-constraints--prefer-native-structured-output) | **Supported.** Format-shaping is one of the most reliable interventions. For machine-consumed output, prefer native structured-output / JSON-schema over a freeform template. |
| **E — Example** (optional) | [Directives §4](/docs/reference/directives/#4-few-shot-examples--for-format-not-for-reasoning) | **Supported, with nuance.** Few-shot gained 10–30 pp on many benchmarks at GPT-3 scale (Brown et al. 2020, [arXiv:2005.14165](https://arxiv.org/abs/2005.14165)). Min et al. 2022 ([arXiv:2202.12837](https://arxiv.org/abs/2202.12837)) then showed *label correctness barely matters* on GPT-3 — what carries the gain is format, label space, and input distribution. Examples teach shape, not facts. |
| **D — Develop** (optional) | (no direct site page) | **Trivially true.** "Iterate" is good advice but not a framework. |

## CRAFT vs. Role + Task + Constraints

CRAFT's five core letters compress into the site's [three-part frame](/docs/patterns/role-task-constraints/):

```text
C            → Role          (with the persona caveat)
R + A        → Task          (request + the steps to perform it)
F            → Constraints
T (+ E)      → Output / examples — orthogonal; lives in directives, not the frame
D            → Iteration loop — not part of any single prompt
```

The three-part frame drops the C-as-PAT idea on purpose. *Persona* (in the "you are JK Rowling" sense) gets demoted to *scope and tone*; *audience* is folded into either scope or constraints; the expertise claim is dropped entirely. Five fewer words, one fewer trap.

CRAFT's *Template* and *Example* are not in the three-part frame because they aren't part of the durable frame — they're per-task output shaping. They live in [directives that work](/docs/reference/directives/) instead.

## Is CRAFT *better* than other methods?

> There is no published head-to-head benchmark of acronym frameworks. The components inside CRAFT are independently studied; the wrapper is decorative.

What *is* measured, across the components CRAFT touches:

- **Specificity** swings accuracy by **up to 76 pp** on classification (Sclar 2023).
- **Persona expertise claims** show **no consistent gain** across 162 personas (Zheng 2024).
- **Negation phrasing** drops performance **20–40 pp** vs. affirmative (Truong 2023).
- **Few-shot for format** gains **10–30 pp** at GPT-3 scale; label correctness barely matters (Brown 2020, Min 2022).
- **Format / template variation** alone produces substantial accuracy swings (same Sclar 2023 finding).

None of these were measured *as CRAFT vs. X*. They were measured as individual interventions. Adopting CRAFT, COSTAR, RACE, or RISEN gives you the same evidence-supported levers in different orders with different cover art. The wrapper choice is essentially free.

Where CRAFT slightly misleads:

1. **First-letter primacy.** Putting Context-as-Persona first signals it's the most important step. The Zheng 2024 result says it isn't.
2. **PAT sub-mnemonic.** Bundling Persona + Audience + Tone hides that two of the three (audience, tone) are stylistic cues that the evidence supports, while the third (persona-as-expertise) is the one that doesn't.
3. **Negation-heavy Frame examples.** The Frame examples in the original post are largely negative ("do not include any other text"). Strong constraint phrasing pairs each prohibition with a positive alternative.

Verdict: **CRAFT is a serviceable beginner checklist for one-shot prompts.** Its gains, where real, come from the specific behaviours it asks you to perform — and those behaviours work under any acronym. For *durable* context (CLAUDE.md, AGENTS.md, system prompts), the [three-part frame](/docs/patterns/role-task-constraints/) maps more cleanly onto how prompt caching and the directive evidence actually work, and avoids the persona trap.

## When CRAFT helps anyway

- **One-shot prompts in a chat UI.** A 30-second mnemonic is genuinely useful when there's no system prompt and no project context to lean on.
- **Teaching beginners.** "Did you specify the output format?" is a higher-value question than "Did you tune your KV-cache prefix?" — meet people where they are.
- **Pre-flight checklist.** Run a prompt through C/R/A/F/T as a quick audit before sending; if any letter is empty, the prompt is probably under-specified.

What CRAFT doesn't replace: layered, cache-stable, durable context. See [layered context](/docs/patterns/layered-context/) and [context is a budget](/docs/foundations/context-is-a-budget/) for that side of the problem.

## Related

- [Role + task + constraints](/docs/patterns/role-task-constraints/) — the three-part frame CRAFT compresses into
- [Directives that work](/docs/reference/directives/) — empirical evidence on specificity, negation, few-shot, persona
- [Failure modes §5 — aspirational rules](/docs/reference/failure-modes/#5-aspirational-rules) — the wider family the "world-class expert" pattern belongs to
- [Negative examples](/docs/patterns/negative-examples/) — the pairing rule CRAFT's Frame examples miss

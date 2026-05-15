---
title: Cite, don't summarize
layout: default
parent: Patterns
nav_order: 5
permalink: /docs/patterns/cite-dont-summarize/
---

# Cite, don't summarize
{: .no_toc }

1. TOC
{:toc}

---

When the model needs to know about a file, *point at the file* — don't paraphrase its contents in your prompt. Paraphrases go stale the moment the file changes. Citations don't.

Every major coding tool has a citation mechanism: Claude Code's `@path` imports, Cursor's `@file` references, Continue.dev's `@-mentions`, Aider's `/read` and file mentions. They exist because the alternative — copying summaries into your context file — is one of the most reliable ways to produce [stale instructions](/docs/reference/failure-modes/#3-stale-instructions).

## The pattern

Two versions of the same context, one bad and one good:

**Bad — paraphrase:**

```markdown
# CLAUDE.md

The user model has fields `id`, `email`, `created_at`, and `is_admin`.
The API uses JWT tokens with a 24-hour expiry. Migrations live in
db/migrations/ and the latest one is 0042_add_admin_flag.sql.
```

**Good — cite:**

```markdown
# CLAUDE.md

See:
- @src/models/user.ts for the user model.
- @docs/auth.md for the JWT setup.
- @db/migrations/ for migrations; never edit shipped ones.
```

The good version is shorter, never goes stale, and gives the model the actual source on demand. The bad version is a snapshot — accurate today, wrong next week, silently misleading the model meanwhile.

## When citation works

Three conditions where citing beats summarizing:

1. **The source file is short enough to read in full.** Under ~2,000 lines is usually fine. Above that, paraphrase or use [retrieval](/docs/patterns/retrieve-before-generate/).
2. **The source changes faster than you'll update the paraphrase.** Almost always true for code; usually true for active docs; sometimes true for spec files.
3. **The model has tool access to read the file when needed.** Claude Code reads `@path` imports at session start; Cursor reads `@file` references on demand. Without tool access, citation degrades to "go look at the filename and hope."

## Mechanisms by tool

Each tool's citation primitive, with the canonical reference:

- **Claude Code** — `@path/to/file` inside CLAUDE.md or skill content. Imports are expanded and loaded into context at launch. Supports recursive imports up to 5 hops deep. ([memory docs](https://code.claude.com/docs/en/memory))
- **Cursor** — `@file`, `@folder`, `@symbol` references inside rules and chat. Files are attached when the rule fires or when explicitly mentioned.
- **Continue.dev** — `@-mentions` in the chat and rules; integrates with the embeddings index.
- **Aider** — `/add` for editable, `/read` for read-only. `read:` in `.aider.conf.yml` for persistent inclusion.
- **AGENTS.md** — plain markdown links. Tools that read AGENTS.md often follow them; the spec doesn't mandate any particular mechanism.

See [front matter cheat sheet](/docs/reference/front-matter/) for the exact field names per tool.

## Grounding: the empirical case for source over summary

Anthropic's own prompt-engineering guidance is explicit about this for long-document tasks:

> "**Ground responses in quotes:** For long document tasks, ask Claude to quote relevant parts of the documents first before carrying out its task. This helps Claude cut through the noise of the rest of the document's contents."
> — [Anthropic prompting best practices](https://platform.claude.com/docs/en/docs/build-with-claude/prompt-engineering/claude-prompting-best-practices)

The mechanism: a summary in your prompt encodes *your* current understanding of the source. The source itself encodes *what's true*. When they diverge — and they always diverge eventually — the agent acts on the summary instead of reality.

[Failure modes §3 — stale instructions](/docs/reference/failure-modes/#3-stale-instructions) covers the symptom side: the agent "fights" the actual code, insists on import paths that were renamed, references commands the repo has migrated past. Paraphrase in your CLAUDE.md is the most common cause.

## When summary still wins

Citation is the right default but not universal. Three cases where paraphrase wins:

1. **The source is too long to load.** A 50,000-line file you only need three rules from. Extract the rules into prose — but be honest with yourself about the maintenance cost.
2. **The source is structured but the rule isn't.** A massive Postgres schema where the only thing the agent needs to know is "user PII columns are `email`, `phone`, `ssn` — never log these." Citing the schema dumps too much; the prose statement is denser.
3. **The source doesn't exist in a readable form.** A binary artifact, a build output, an external API. Paraphrase from the docs, and link to the docs.

Even in these cases, *link to the canonical source* in the paraphrase. Anyone updating the paraphrase later needs to know what they're keeping in sync with.

## How citation and perception interact

A maintained [perception.md](/docs/foundations/perception-over-history/) is itself an exercise in citation discipline. The Working set layer:

```yaml
file: src/services/points.ts
hypothesis: idempotency belongs in the service, not the schema
recent-tool-results:
  - bun test points.spec.ts → 1 failed (idempotency)
  - rg "awardPoints" → 0 callers yet
```

…does not paraphrase `points.ts`. It *names* it. The agent can read the file on demand; what the perception captures is the agent's belief about the file, not the file itself. Same principle, applied to working memory instead of project context.

If you find your perception.md repeating code that lives in actual files, you're paraphrasing where you should be citing. Replace with `@`-style references.

## Failure modes

- **Stale paraphrase.** You paraphrased `package.json` six months ago; the project has since migrated `pnpm` → `bun`. The agent runs `pnpm test` and is confused when it fails. See [failure modes §3](/docs/reference/failure-modes/#3-stale-instructions).
- **Phantom files.** A citation to `@docs/api.md` for a file that no longer exists. Some tools warn; most don't. Lint your citations: a CI check that every `@path` resolves saves hours of confused debugging.
- **Over-citation.** A CLAUDE.md that cites 40 files at session start, each of which loads in full, leaves no token budget for the actual task. Cite selectively; let path-scoped rules or skills handle the long tail.
- **Citing without context.** *"See @src/services/points.ts"* with no hint at *why* — the agent reads the file but doesn't know what to look for. Annotate: *"See @src/services/points.ts for the idempotency pattern other services should follow."*

## Related

- [Retrieve before generate](/docs/patterns/retrieve-before-generate/) — citation's bigger cousin for large external corpora
- [Perception over history](/docs/foundations/perception-over-history/) — citation discipline applied to working memory
- [Crafting a CLAUDE.md](/docs/per-tool/claude-md/) — what to cite from your CLAUDE.md
- [Failure modes §3 — stale instructions](/docs/reference/failure-modes/#3-stale-instructions)

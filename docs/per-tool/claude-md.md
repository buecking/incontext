---
layout: default
title: Crafting a CLAUDE.md
parent: Per-tool
nav_order: 1
permalink: /docs/per-tool/claude-md/
---

# Crafting a CLAUDE.md
{: .no_toc }

1. TOC
{:toc}

---

`CLAUDE.md` is the project file Claude Code reads automatically when it starts working in a directory. It is the single most consequential context resource in a Claude Code project — every session reads it, every action is shaped by it, every stale line in it silently makes the model worse for as long as it sits there.

This page is about how to write one well.

{: .note }
> The format and behavior evolve. When something here disagrees with [Anthropic's official memory docs](https://code.claude.com/docs/en/memory), trust theirs.

## How Claude Code loads it

Five locations, loaded in this order — broadest scope first, so the closer-to-cwd files end up *later* in context and win on conflict:

```text
/Library/Application Support/ClaudeCode/CLAUDE.md   # macOS managed policy
/etc/claude-code/CLAUDE.md                          # Linux managed policy
~/.claude/CLAUDE.md                                 # personal (all projects)
./CLAUDE.md  or  ./.claude/CLAUDE.md                # project, committed
./CLAUDE.local.md                                   # project, gitignored
```

Files in *subdirectories* of the project are also discovered. When Claude reads a file in `frontend/`, it loads `frontend/CLAUDE.md` if present — adding to the context for that work without bloating the root file. See [scope by directory](/docs/patterns/scope-by-directory/) for the broader pattern.

This layering is the single most underused feature of the format. Most people put everything in the root file and watch it grow into an unreadable wall.

## The shape that works

A `CLAUDE.md` is not a manifesto. It is a working document the model reads on *every* run, which means every line costs you something on every run forever. The discipline is brutal subtraction.

A good `CLAUDE.md` typically covers:

1. **What this project is.** One or two sentences. The model can usually figure it out from the code, but stating it directly removes ambiguity for free.
2. **Stack and conventions.** Language, package manager, test runner, formatter. The non-obvious choices.
3. **Commands the model should use.** `pnpm test`, `make lint`, the deploy script — whatever the model would otherwise re-derive every time. Make them copy-pasteable.
4. **Directory map, only where it's non-obvious.** Don't recreate `tree`. Do flag things like *"schemas live in `db/schema/` and are the source of truth for migrations."*
5. **Standing rules.** *"Never edit generated files in `dist/`." "All new endpoints go in `routes/v2/`."* Things that are true across tasks.
6. **Known gotchas.** The thing that bit you last week and will bite the model next week.

Anthropic's own guidance is to keep each `CLAUDE.md` under 200 lines. Pages that grow beyond that stop being followed reliably — adherence drops as length grows. The [smart-zone framing](/docs/foundations/smart-zone-and-dumb-zone/) is one reason; the [lost-in-the-middle effect](/docs/foundations/long-context-degradation/) is another.

{: .tip }
> When in doubt, write the rule and then immediately ask: *would the model do the wrong thing without this line?* If you can't name the wrong thing, the line probably doesn't belong.

## What to leave out

- **Anything obvious from the repo.** If the model can see `package.json`, it doesn't need to be told you use TypeScript. Anthropic's documentation puts this bluntly: include what the model *will get wrong without*, not everything true about the project.
- **Aspirational rules.** If you don't actually follow it, the model shouldn't either — it produces confused output that mixes the rule with the actual codebase. See [failure modes §5](/docs/reference/failure-modes/#5-aspirational-rules).
- **Marketing copy or backstory.** The README is for humans. `CLAUDE.md` is for the model.
- **Long examples.** If you need an example, point at a real file. Imports cost nothing on stable code; embedded examples go stale.
- **Expert-persona claims.** *"You are a senior backend engineer with 20 years of experience"* — empirical evidence is that this does not boost factual accuracy and may increase confident hallucinations. See [directives §6](/docs/reference/directives/#6-role--persona-prompts--for-style-not-for-capability).
- **"Let's think step by step."** Useful on non-reasoning models; counterproductive on Claude with extended thinking. See [directives §5](/docs/reference/directives/#5-chain-of-thought-triggers--only-on-non-reasoning-models).

## Using `@path` imports

Claude Code expands `@path` references inside `CLAUDE.md` into the actual file contents at session start. This means you can keep `CLAUDE.md` small and pull in deeper material only where it's load-bearing:

```markdown
# Acme platform

E-commerce platform for the Acme catalog.

See @README.md for project overview and @package.json for npm commands.

# Coding rules
@docs/conventions.md

# Architecture
@docs/architecture-overview.md
```

A few rules of thumb:

- **Imports recurse up to 5 hops deep.** Don't build deep import chains; the deepest layer often gets truncated or lost.
- **Block-level HTML comments (`<!-- ... -->`) are stripped** before injection. Use them to leave notes for humans without paying tokens.
- **The imported file's full content is loaded.** If you import a 5,000-line `architecture-overview.md`, that's now in every session. Either trim the imported file or extract only the relevant section.
- **Imports beat copy-paste.** A copied snippet goes stale the moment the source changes. See [cite, don't summarize](/docs/patterns/cite-dont-summarize/).

## Before and after

A common `CLAUDE.md` that has grown wrong:

```markdown
# Acme

Acme is a fast-growing e-commerce startup serving the catalog space.
We pride ourselves on customer obsession and operational excellence.

## You

You are a world-class senior engineer with 20+ years of experience
in TypeScript, React, Node.js, Postgres, Redis, AWS, GCP, Docker,
Kubernetes, and microservices architecture. Let's think step by step.

## Stack

We use TypeScript, React, Bun, Postgres. Our package manager is bun
which we migrated to from pnpm last quarter. Tests are written in
Vitest. Wait, actually we use Bun test now. Both still work.

## Conventions

Please always write clean code. Make sure to handle errors properly.
Use descriptive variable names. Don't use any. Don't use var.
Don't write tests after the code. Don't add comments unless needed.

## Things to know

[850 lines of architecture decisions, rationale, and historical context]
```

What's wrong:
- Marketing intro ("customer obsession") — fluff.
- Expert persona — no measurable benefit, potential for over-confident output.
- "Let's think step by step" — counterproductive on extended thinking.
- Stack section is internally contradictory (Vitest vs Bun test) — agent will pick one, often wrong.
- "Please always write clean code" — vague, unmeasurable, [bare imperatives](/docs/reference/directives/#2-bare-imperatives-second-person) would beat this.
- Negative-only constraints ("don't use any") — see [negative examples](/docs/patterns/negative-examples/).
- 850 lines of architecture — over budget by a factor of four.

The rewrite, under 60 lines:

```markdown
# Acme

E-commerce platform for the Acme catalog. TypeScript / Bun monorepo.

## Setup
- Install: `bun install`
- Test: `bun test`
- Test one file: `bun test path/to/file.test.ts`
- Lint: `bun lint`
- Typecheck: `bun typecheck`
- Dev server: `bun dev`

## Stack
- Runtime: Bun 1.1+ (migrated from pnpm/Node — `pnpm` and `vitest` no longer work)
- Database: Postgres 16 via the `db/` package
- Frontend: React 19 + Vite (in `packages/web/`)

## Conventions
- Commit messages: conventional commits (`feat:`, `fix:`, `docs:`).
- Vertical slices: one PR cuts through schema → service → API → UI.
- Tests before code. Red, green, refactor.
- TypeScript strict mode. Use `unknown` over `any` for untyped values.
- snake_case for SQL columns; camelCase for TypeScript identifiers.

## Architecture
See @docs/architecture/overview.md for the system map.
See @docs/architecture/services.md for service boundaries.

## Gotchas
- Migrations in `db/migrations/` are immutable once on `main`. For schema
  changes, create a new migration with the next number.
- `bun build` produces a single binary; do not commit `dist/`.
- The Stripe webhook handler depends on Redis. Run `bun dev:redis` first.

## Out of scope
- `vendor/` is third-party code — never edit.
- `legacy/` is being deleted slice by slice — don't add features.
```

Every line earns its place. The architecture material lives in cited files, not pasted in. The expert persona is gone. The conflicting stack info is reconciled (with the migration noted explicitly so the agent doesn't try the old commands).

## Keeping it alive

The failure mode for `CLAUDE.md` is the same as for any documentation: it goes stale, the project moves, and now the model is being told things that aren't true. The agent will weight the stale imperative over live evidence — see [stale instructions](/docs/reference/failure-modes/#3-stale-instructions).

Three habits:

- **Treat staleness as a bug.** When you change a convention, change the file in the same commit. Reviewers should reject PRs that change conventions without updating `CLAUDE.md`.
- **Lint commands.** A CI check that every command in `CLAUDE.md` exists in `package.json` / `Makefile` / wherever costs nothing and catches the most common drift.
- **Re-read it quarterly.** Out loud, ideally. Anything you flinch at — outdated, aspirational, redundant — cut it.

The Claude Code `/init` command can regenerate a `CLAUDE.md` from current repo state. Useful for the first draft and as a quarterly diff against the live file.

## When `AGENTS.md` is the better choice

If your team uses more than one agent tool, or your project is open source, [`AGENTS.md`](/docs/per-tool/agents-md/) at the repo root is the lower-friction choice. The same content shape works; the file is just portable across tools. You can then keep a minimal `CLAUDE.md` that imports the shared file and adds Claude-specific overrides:

```markdown
@AGENTS.md

## Claude Code specific
- Use plan mode for changes under `src/billing/`.
- The agent should not start work on tasks tagged `[design-review]` —
  those need human design sign-off first.
```

## A starter template

```markdown
# <Project name>

<One-sentence description.>

## Setup
- Install: `<command>`
- Test: `<command>`
- Lint: `<command>`

## Stack
- <Language + version>
- <Test runner>
- <Anything non-obvious>

## Conventions
- <Rule>
- <Rule>

## Gotchas
- <Thing that bites>
```

Start there. Add only when you've watched the model do the wrong thing twice and can articulate the rule that would have prevented it. Resist the urge to pre-populate.

## Related

- [AGENTS.md and the convergence](/docs/per-tool/agents-md/) — the cross-tool form of the same idea
- [Scope by directory](/docs/patterns/scope-by-directory/) — multi-level `CLAUDE.md` files
- [Cite, don't summarize](/docs/patterns/cite-dont-summarize/) — why `@path` imports beat copy-paste
- [Context is a budget](/docs/foundations/context-is-a-budget/) — why "under 200 lines" matters
- [Failure modes §3 — stale instructions](/docs/reference/failure-modes/#3-stale-instructions)
- [Failure modes §5 — aspirational rules](/docs/reference/failure-modes/#5-aspirational-rules)

## Sources

- [Claude Code — CLAUDE.md and auto memory](https://code.claude.com/docs/en/memory) — the canonical reference for loading behavior, `@path` imports, and recommended length.

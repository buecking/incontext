---
layout: default
title: AGENTS.md and the convergence
parent: Per-tool
nav_order: 2
permalink: /docs/per-tool/agents-md/
---

# AGENTS.md and the convergence
{: .no_toc }

1. TOC
{:toc}

---

For a while, every agentic coding tool wanted its own context file. Cursor had `.cursorrules`, then `.cursor/rules/`. Claude Code introduced `CLAUDE.md`. Aider had `CONVENTIONS.md`. Continue.dev had `.continue/rules/`. Copilot had `.github/copilot-instructions.md`. Anyone using more than one tool was maintaining three or four near-duplicate files and praying they stayed in sync.

`AGENTS.md` is the convergence. A deliberately tool-agnostic file — same idea as `CLAUDE.md`, framed as a shared standard rather than one vendor's format. As of 2026 it is read by 25+ agent tools including Codex, Cursor, Aider, Copilot, Claude Code (via import), Zed, JetBrains Junie, Devin, and others. The [spec at agents.md](https://agents.md/) says itself: *"AGENTS.md is just standard Markdown. Use any headings you like; the agent simply parses the text you provide."*

That minimalism is the point. The format is a coordination move, not a feature.

## Should you use it?

Three cases, three answers.

**Single-tool, no portability concerns.** Tool-native is fine. If your team is on Claude Code only, `CLAUDE.md` gives you `@path` imports, multi-level loading, and the specific behaviors Anthropic's docs guarantee. Cursor-only teams should write `.cursor/rules/`. Don't add `AGENTS.md` just because it exists.

**Mixed tools across a team, or open-source project.** `AGENTS.md` at the repo root, full stop. Anyone cloning the repo gets working context regardless of what they edit with. Several tools (Cursor, Aider, Codex) read it directly; others (Claude Code) read it via an `@AGENTS.md` import or a symlink. The cost is one file you maintain; the benefit is your project working out-of-the-box for every contributor.

**Already maintaining a long `CLAUDE.md`.** Move the tool-agnostic content to `AGENTS.md`, leave only the Claude-specific overrides in `CLAUDE.md`. The result reads better and your project becomes portable for free.

## What goes in it

Everything from [the CLAUDE.md guidance](/docs/per-tool/claude-md/) applies — stack, commands, conventions, gotchas. The cross-tool framing is mostly about *what to leave out*. Avoid instructions that only make sense for one tool's UI or workflow, since `AGENTS.md` will be read by agents that don't have those affordances.

The conventional section structure that's emerging in the wild (from looking at 60,000+ OSS projects with the file at repo root):

```markdown
# Project name

One-sentence description.

## Setup
- Install: `<command>`
- Run: `<command>`
- Test: `<command>`
- Lint: `<command>`

## Stack
- Language + version
- Test runner
- Anything non-obvious

## Conventions
- <rule>
- <rule>

## Code style
- <rule>
- <rule>

## Gotchas
- <thing that bites>

## Out of scope
- <thing the agent should not touch>
```

Not all sections will apply to every project. The spec is intentionally non-prescriptive — pick the headings you need, drop the rest. Two principles cut across:

- **Make commands copy-pasteable.** Agents will try to run them verbatim. If your test command needs a flag, write the flag.
- **Cite, don't paraphrase.** When the rule lives somewhere else (`package.json`, `Makefile`, a real doc), point at it. See [cite, don't summarize](/docs/patterns/cite-dont-summarize/).

## Nested files for monorepos

The spec is explicit: *"Place another AGENTS.md inside each package. Agents automatically read the nearest file in the directory tree, so the closest one takes precedence and every subproject can ship tailored instructions."*

OpenAI's own monorepo reportedly ships 88 `AGENTS.md` files. The pattern at scale:

```text
your-monorepo/
├── AGENTS.md                        # repo-wide: language, setup, common rules
├── packages/
│   ├── api/
│   │   └── AGENTS.md                # API conventions
│   ├── frontend/
│   │   └── AGENTS.md                # React conventions
│   └── migrations/
│       └── AGENTS.md                # immutability rule
```

When an agent works in `packages/api/`, it reads the root file *and* the API file, with the API file winning on conflict. See [scope by directory](/docs/patterns/scope-by-directory/) for the broader pattern.

## How it composes with tool-native files

Each major tool has its own way of integrating `AGENTS.md` alongside the tool-native file. The pattern that emerged:

**Claude Code.** `AGENTS.md` is not loaded by default. Either import it from `CLAUDE.md`:

```markdown
@AGENTS.md

## Claude Code specific
- Use plan mode for changes under `src/billing/`.
- The agent has filesystem access; the human reviews every diff.
```

…or symlink (Unix-y systems only):

```bash
ln -s AGENTS.md CLAUDE.md
```

The import approach is cleaner because it lets you keep Claude-specific guidance separate. The symlink approach is fine for projects with no Claude-specific overrides.

**Cursor.** Reads `AGENTS.md` automatically alongside `.cursor/rules/`. The rules files take precedence for matching paths.

**Aider.** Read explicitly via `aider --read AGENTS.md` or persistently in `.aider.conf.yml`:

```yaml
read: AGENTS.md
```

**OpenAI Codex.** Reads `AGENTS.md` from the repo root automatically; no configuration needed.

**GitHub Copilot Coding Agent.** Reads `AGENTS.md` for cloud-agent runs alongside `.github/copilot-instructions.md`.

See [front matter cheat sheet](/docs/reference/front-matter/) for the exact loading behavior per tool.

## A worked example

A real `AGENTS.md` for a TypeScript / Bun monorepo, kept under 60 lines:

```markdown
# Acme platform

E-commerce platform for the Acme catalog. TypeScript / Bun monorepo.

## Setup
- Install: `bun install`
- Dev server: `bun dev`
- Test: `bun test`
- Test one file: `bun test path/to/file.test.ts`
- Lint: `bun lint`
- Typecheck: `bun typecheck`

## Stack
- Runtime: Bun 1.1+
- Database: Postgres 16 via `db/` package
- Frontend: React 19 + Vite (in `packages/web/`)
- Test framework: `bun test` (not Vitest, not Jest)

## Conventions
- Commit messages: conventional commits (`feat:`, `fix:`, `docs:`).
- One PR = one slice. Vertical (schema → service → API → UI), not horizontal.
- Tests before code. Red-green-refactor. No exceptions.
- Public service methods get unit tests; private helpers don't.

## Code style
- TypeScript with strict mode. No `any` — use `unknown` for untyped values.
- snake_case for SQL columns, camelCase for TypeScript identifiers.
- React components in `PascalCase.tsx`, hooks in `useThing.ts`.

## Gotchas
- Migrations in `db/migrations/` are immutable once on `main`. Add a new
  migration for schema changes — never edit an existing one.
- `bun build` produces a single binary; do not commit `dist/`.
- The Stripe webhook handler in `packages/api/src/stripe/` has rate-limit
  logic that depends on Redis. Local dev requires `bun dev:redis` first.

## Out of scope
- The `vendor/` directory is third-party code. Never edit.
- The `legacy/` directory is being deleted slice by slice. Don't add features.
```

That file works in any of the 25+ tools that read `AGENTS.md`. Editing it is the maintenance cost of being multi-tool compatible.

## Common mistakes

- **Duplicating content across `AGENTS.md` and `CLAUDE.md`.** Pick one source of truth. If the rule belongs in both, put it in `AGENTS.md` and import from `CLAUDE.md`.
- **Putting tool-specific UI references in `AGENTS.md`.** "Use the plan mode" only makes sense in Claude Code. Keep it in the tool-native file.
- **Letting it grow past a screen.** The same advice applies as for `CLAUDE.md`: under 200 lines, ideally under 100. Long files don't get followed; they get skimmed. See [context is a budget](/docs/foundations/context-is-a-budget/).
- **Treating it as documentation.** The README is for humans. `AGENTS.md` is for the model. They overlap but they aren't the same file. (If you have neither, *write the README first.*)

{: .tip }
> When you're about to add something to `AGENTS.md`, ask: would this also help a new human contributor on their first day? If yes, it might belong in the README and be linked from `AGENTS.md`. If no, it stays.

## The pattern that's emerging

The interesting thing about `AGENTS.md` isn't the file format — it's barely a format, just markdown. It is the implicit acknowledgment that **the context resource is now part of the project**, the same way a `Makefile` or a `.editorconfig` is. A piece of the repo that exists to make tooling work, expected to be there, version-controlled like everything else.

Five years ago this category didn't exist. Today it is converging on a name and a location.

In a year or two the question won't be "should I have an `AGENTS.md`?" The question will be "what's in your `AGENTS.md`?" Worth getting ahead of.

## Related

- [Crafting a CLAUDE.md](/docs/per-tool/claude-md/) — the Claude-specific guidance that `AGENTS.md` generalizes
- [Scope by directory](/docs/patterns/scope-by-directory/) — how nested `AGENTS.md` files compose
- [Front matter cheat sheet](/docs/reference/front-matter/) — exact load behavior across tools
- [Context is a budget](/docs/foundations/context-is-a-budget/) — why "under 200 lines" matters

## Sources

- [AGENTS.md spec](https://agents.md/) — the canonical reference.
- [agentskills.io — Client Showcase](https://agentskills.io) — the cross-tool implementer list (overlapping with AGENTS.md adopters).

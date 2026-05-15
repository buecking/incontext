---
title: Scope by directory
layout: default
parent: Patterns
nav_order: 1
permalink: /docs/patterns/scope-by-directory/
---

# Scope by directory
{: .no_toc }

1. TOC
{:toc}

---

Don't put every rule in the root `CLAUDE.md`. Let the filesystem carry the layering: rules that apply everywhere live at the root, rules that only apply to one part of the codebase live next to that code. The agent picks them up automatically when it works in that subdirectory.

This is the single most underused feature of every context-file format in production.

## What it is

Every major AI coding tool reads context files at multiple levels of the directory tree and concatenates them, with closer-to-cwd files winning on conflict:

- **Claude Code** walks up from the working directory and concatenates every `CLAUDE.md` and `CLAUDE.local.md` it finds. Subdirectory files are also loaded on demand when Claude reads files in those directories. ([docs](https://code.claude.com/docs/en/memory))
- **Cursor** supports nested `.cursor/rules/` directories — rules apply to their containing directory and below.
- **Continue.dev** discovers `.continue/rules/` files recursively.
- **Aider** can load any `CONVENTIONS.md` from any directory via `--read`.
- **AGENTS.md** is explicit: nested files in a monorepo override the root for that subtree, with "the closest one taking precedence." ([spec](https://agents.md/))

The pattern is the same across all of them: **closer wins, distant accumulates.**

## When to reach for it

Three signals that you should split a context file by directory:

1. **The root file is over ~200 lines.** Anthropic's own guidance for `CLAUDE.md` is to target under 200 lines per file because adherence drops as length grows. ([Claude Code memory docs](https://code.claude.com/docs/en/memory))
2. **Half the rules are about one part of the codebase.** If your CLAUDE.md has a "Frontend" section, a "Backend" section, and a "Migrations" section, those should be three separate files in three subdirectories.
3. **Different teams own different subtrees.** Your team's conventions don't belong in another team's working directory, and vice versa.

## How to apply it

The canonical layout for a Claude Code project:

```text
your-project/
├── CLAUDE.md                          # global: stack, commands, conventions
├── frontend/
│   └── CLAUDE.md                      # React conventions, component patterns
├── backend/
│   ├── CLAUDE.md                      # API conventions, error handling
│   └── api/
│       └── CLAUDE.md                  # specific to v2 endpoints
└── db/
    ├── CLAUDE.md                      # migration rules, schema conventions
    └── migrations/
        └── CLAUDE.md                  # immutability rule for shipped migrations
```

When Claude Code starts in `backend/api/`, it loads — in order — the root `CLAUDE.md`, then `backend/CLAUDE.md`, then `backend/api/CLAUDE.md`. Closest wins on conflicts.

For Cursor, the same idea using `.cursor/rules/`:

```text
your-project/
├── .cursor/rules/
│   └── conventions.mdc                # global
├── frontend/
│   └── .cursor/rules/
│       └── react.mdc                  # React-only
└── backend/
    └── .cursor/rules/
        └── api.mdc                    # API-only
```

For path-scoping *without* directory splitting, both Claude Code and Cursor support a `paths`/`globs` field in the rule's frontmatter — the rule lives in one place but only activates on matching files:

```yaml
---
paths:
  - "src/api/**/*.ts"
---
```

See [front matter cheat sheet](/docs/reference/front-matter/) for the exact field names per tool.

## Why this works

Three reasons it pays for itself:

1. **Token economics.** Rules that don't apply to the current task aren't competing for attention. A rule about React component naming spending tokens during a backend migration is a rule that pulled attention away from migration rules.
2. **Cache stability.** Directory-scoped files change less often than monolithic ones, which keeps the agent's [prompt cache](/docs/foundations/perception-over-history/) warmer.
3. **Reviewability.** A `db/migrations/CLAUDE.md` that says "never edit shipped migrations" lives next to the code it constrains. Future you grep'ing for the rule will find it immediately.

## Failure modes

The pattern is forgiving but two ways it goes wrong:

- **Inheritance collisions you didn't see.** A rule in the root that contradicts a rule in a subdirectory. The closer file wins, but if you forgot the root rule existed, you'll be confused when the agent ignores it in some directories. Run `/memory` (Claude Code) to see exactly which files are loaded in the current session. See [failure modes §4](/docs/reference/failure-modes/#4-instruction-conflict).
- **Stale subdirectory files.** A `frontend/CLAUDE.md` from when you used Vue, still sitting there now that you've migrated to React. Subdirectory files go stale faster than root files because they're touched less. Treat them as code — review them in PRs that change that subtree.

## Related

- [Layered context](/docs/patterns/layered-context/) — the broader pattern this is a special case of
- [Front matter cheat sheet](/docs/reference/front-matter/) — exact path-scoping fields per tool
- [Crafting a CLAUDE.md](/docs/per-tool/claude-md/) — what to put in each file
- [Failure modes §4 — instruction conflict](/docs/reference/failure-modes/#4-instruction-conflict)

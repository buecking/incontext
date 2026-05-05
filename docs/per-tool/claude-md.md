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

`CLAUDE.md` is a markdown file Claude Code reads automatically when it starts working in a directory. Its job is simple: tell the model the things it would otherwise have to guess about your project.

This page is about how to write one well.

{: .note }
> The format and behavior evolve. When something here disagrees with Anthropic's official docs, trust theirs.

## The shape that works

A `CLAUDE.md` is not a manifesto. It's a working document the model reads on *every* run, which means every line you add costs you something on every run forever. The discipline is brutal subtraction.

A good `CLAUDE.md` typically covers:

1. **What this project is.** One or two sentences. The model can usually figure this out from the code, but stating it directly removes ambiguity for free.
2. **Stack and conventions.** Language, package manager, test runner, formatter. The non-obvious choices.
3. **Directory map, only where it's non-obvious.** Don't recreate `tree`. Do flag things like "schemas live in `db/schema/` and are the source of truth for migrations."
4. **Commands the model should use.** `pnpm test`, `make lint`, the deploy script — whatever the model would otherwise re-derive every time.
5. **Standing rules.** "Never edit generated files in `dist/`." "All new endpoints go in `routes/v2/`." Things that are true across tasks.
6. **Known gotchas.** The thing that bit you last week and will bite the model next week.

## What to leave out

- **Anything obvious from looking at the repo.** If the model can see `package.json`, it doesn't need to be told you use TypeScript.
- **Aspirational rules.** If you don't actually follow it, the model shouldn't either — it'll produce confused output that mixes the rule with the actual codebase.
- **Marketing copy or backstory.** The README is for humans. `CLAUDE.md` is for the model.
- **Long examples.** If you need an example, point at a real file in the repo.

## A useful pattern: scope by directory

Claude Code reads `CLAUDE.md` files at multiple levels of the tree, with closer files taking precedence. This means you can put repo-wide rules at the root and put narrower rules deeper. A `CLAUDE.md` in `frontend/` can talk about React conventions without bloating the root file for backend work.

This is the single most underused feature of the format. Most people put everything in the root file and watch it grow into an unreadable wall.

## Keeping it alive

The failure mode for `CLAUDE.md` is the same as for any documentation: it goes stale, the project moves, and now the model is being told things that aren't true anymore. Two habits help:

- **Treat staleness as a bug.** When you change a convention, change the file in the same commit.
- **Re-read it quarterly.** Out loud, ideally. Anything you flinch at — outdated, aspirational, redundant — cut it.

## A starter template

```markdown
# <Project name>

<One-sentence description of what this is.>

## Stack
- <Language + version>
- <Package manager>
- <Test runner>
- <Anything else non-obvious>

## Commands
- `<command>` — <what it does>
- `<command>` — <what it does>

## Conventions
- <Rule>
- <Rule>

## Gotchas
- <Thing that will bite you>
```

Start there. Add only when you've watched the model do the wrong thing twice and can articulate the rule that would have prevented it. Resist the urge to pre-populate.

## Related

- [AGENTS.md and the convergence](/docs/per-tool/agents-md/)
- [Context is a budget](/docs/foundations/context-is-a-budget/)

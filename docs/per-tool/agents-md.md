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

For a while, every agentic coding tool wanted its own context file. Cursor had `.cursorrules`, then `.cursor/rules/`. Claude Code introduced `CLAUDE.md`. Aider had its own thing. Continue had its own thing. If you used more than one, you maintained three or four near-duplicate files.

`AGENTS.md` is the convergence. It's a deliberately tool-agnostic file — same idea as `CLAUDE.md` but framed as a shared standard rather than one vendor's format. A growing number of agent runners read it, and the trajectory is toward more.

## Should you use it?

If you're working in a single tool exclusively, the tool-native file is fine. `CLAUDE.md` for Claude Code, Cursor rules for Cursor.

If you're working across tools, or want your project to be portable for collaborators using different setups, `AGENTS.md` at the repo root is the lower-friction choice. Some tools will read both, with the tool-native file taking precedence — meaning you can put the shared baseline in `AGENTS.md` and put tool-specific overrides in `CLAUDE.md` or `.cursor/rules/`.

## What goes in it

Everything from [the CLAUDE.md guidance](/docs/per-tool/claude-md/) applies. Stack, commands, conventions, gotchas. The cross-tool framing is mostly about *what to leave out*: avoid instructions that only make sense for one tool's UI or workflow, since `AGENTS.md` will be read by tools that don't have those affordances.

## The pattern that's emerging

The interesting thing about `AGENTS.md` isn't the file format — it's barely a format at all, just markdown. It's the implicit acknowledgment that **the context resource is now part of the project**, the same way a `Makefile` or a `.editorconfig` is. It's a piece of the repo that exists to make tooling work, and it's expected to be there.

Five years ago this category didn't exist. Today it's converging on a name. Worth paying attention to.

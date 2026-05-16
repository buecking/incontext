---
title: What is a context resource?
layout: default
parent: Foundations
nav_order: 1
permalink: /docs/foundations/what-is-a-context-resource/
---

# What is a context resource?
{: .no_toc }

1. TOC
{:toc}

---

## The short version

A **context resource** is any artifact you write or maintain whose primary purpose is to be read by an AI model — usually before or alongside whatever real task you've asked it to do.

It is not the user's question. It is not the model's training data. It sits in between: material you've curated specifically to shape the model's behavior on this project, in this tool, for this kind of task.

## The common examples

- **`CLAUDE.md`** — the project file [Claude Code reads on every run](/docs/per-tool/claude-md/).
- **`AGENTS.md`** — the increasingly common [cross-tool equivalent](/docs/per-tool/agents-md/). Cursor, Aider, Continue, Codex, Copilot, and 20+ others read this now.
- **`.cursor/rules/`** — Cursor's per-project rule files, broken up by scope.
- **`SKILL.md`** — [Agent Skills format](/docs/reference/) files: named, reusable workflows that load on demand.
- **Sub-agent definitions** — `.claude/agents/*.md` files describing specialized agents the main agent can delegate to.
- **System prompts** — the top-level frame for chat-style use.
- **RAG sources** — the documents your retrieval layer surfaces to the model.
- **MCP server descriptions** — the natural-language `description` fields on tools the agent calls.

What unites these is that they're all *deliberate context*: material someone has curated specifically to shape the model's behavior. They are not training data (which the model already has). They are not the user's task (which is ephemeral, scoped to one request). They live in between — between *what the model knows* and *what you want it to do right now*.

## A test for "is this a context resource?"

Three questions. All three should land *yes*:

1. **Was it written specifically to be read by the model?** A README written for humans that the model also happens to read is not a context resource. A CLAUDE.md is.
2. **Is it deliberately curated, not incidentally produced?** A chat transcript is not a context resource; it's a log. A `perception.md` that summarizes the same content into belief state is.
3. **Does it persist across at least one interaction?** A one-off prompt is not a context resource; a system prompt that frames every prompt for the next month is.

A few edge cases the test resolves:

- **Tool descriptions in MCP manifests.** Yes — written for the model, deliberately curated, persistent. (And, as the [tool-poisoning failure mode](/docs/reference/failure-modes/#14-tool-poisoning-mcp) shows, also a vector when an adversary controls the curation.)
- **Slash command markdown files in `.claude/commands/`.** Yes — same shape as skills.
- **Type definitions and JSDoc comments.** Borderline. Written for humans but read by the model. Treat as context-adjacent.
- **Git history.** No — produced incidentally, not curated to shape behavior.

## Why the category matters

Three years ago "prompt engineering" covered all of this. The phrase has aged poorly because the work is no longer mostly about cleverly worded prompts. The work is about **deciding what context to make available, in what shape, for what scope, with what lifecycle.**

That's a different skill — closer to information architecture than to copywriting.

Once you start treating these artifacts as a category, useful questions appear:

- **What's the right size?** Almost always: smaller than your first instinct. See [context is a budget](/docs/foundations/context-is-a-budget/).
- **What scope?** Repo, directory, task, session, user? Each scope has a natural file location and a natural cadence of update.
- **How does it interact with other context the model is seeing?** Conflicts between sources cause [instruction-conflict failures](/docs/reference/failure-modes/#4-instruction-conflict). Designate one source of truth per topic.
- **How do you keep it from going stale?** Treat it as code. Review in PRs. Lint commands against `package.json`. Re-read quarterly.
- **How do you test that it's actually doing something?** Remove it for a session and see what changes. If nothing changes, the line wasn't doing work.

The rest of this site works through those questions, one resource type at a time.

## The taxonomy by scope and cadence

Context resources differ on two axes that matter more than any other: **scope** (who or what does it apply to) and **cadence** (how often does it change).

| | Changes rarely | Changes per-feature | Changes per-action |
|---|---|---|---|
| **Personal** | `~/.claude/CLAUDE.md` (your conventions) | personal scratch notes | the chat itself |
| **Project** | `CLAUDE.md`, `AGENTS.md` (stack, rules) | `.claude/commands/`, perception.md frame | the current user message |
| **Subdirectory** | `frontend/CLAUDE.md` (local conventions) | `.cursor/rules/*.mdc` with paths | tool results for files there |
| **Skill / task** | `SKILL.md` invariants | `SKILL.md` body for a workflow | the current invocation |

That table is the map. Each cell has a natural home in the filesystem and a natural lifecycle. Putting a fact in the wrong cell is the most common authoring mistake — see [layered context](/docs/patterns/layered-context/) for the full discussion.

## The lifecycle

A context resource has four phases, and most teams handle only the first one well.

1. **Authoring.** Someone writes it. Usually with too much detail and too much aspirational content; see [aspirational rules](/docs/reference/failure-modes/#5-aspirational-rules).
2. **Use.** The model reads it, on every session, for as long as it exists. Every line is paying recurring rent.
3. **Maintenance.** The project moves. Conventions change. Commands get renamed. The file does not move with the project unless someone makes it.
4. **Retirement.** A piece of the file stops being true. Either the file is updated or — far more commonly — the line just rots, and the model starts being told things that aren't real.

The lifecycle implies the maintenance discipline: every PR that changes a convention should change the corresponding context resource. Reviewers should reject PRs that drift them apart. CI can lint commands against the real toolchain. None of this is exotic; it just requires *treating context resources as code* — version-controlled, reviewed, and tested.

## What it isn't

Three distinctions that come up repeatedly:

- **Not training data.** Training data is what the model already knows. Context resources are what it reads *now*. The model doesn't learn from a CLAUDE.md across sessions; each session re-reads it. This is also why context resources can be edited without retraining anything.
- **Not the user's prompt.** The user's prompt is the task. The context resource is the frame in which the task is interpreted. The same prompt produces different output under different context resources — that's the entire point.
- **Not documentation for humans.** The README and the CLAUDE.md overlap but are not the same file. Humans skim; models read literally. Aspirational documentation that humans tolerate ("we *should* be writing tests") becomes confused output when a model reads it as fact.

## Related

- [Context is a budget, not a bucket](/docs/foundations/context-is-a-budget/) — the economics
- [Layered context](/docs/patterns/layered-context/) — the scope/cadence taxonomy made operational
- [Crafting a CLAUDE.md](/docs/per-tool/claude-md/) — the most consequential context resource in a Claude Code project
- [AGENTS.md and the convergence](/docs/per-tool/agents-md/) — the cross-tool form

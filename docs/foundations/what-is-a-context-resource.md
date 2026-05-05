---
layout: default
title: What is a context resource?
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

- **`CLAUDE.md`** — the project file Claude Code reads on every run.
- **`AGENTS.md`** — the increasingly common cross-tool equivalent. Cursor, Aider, Continue, and several others read this now.
- **`.cursor/rules/`** — Cursor's per-project rule files, broken up by scope.
- **System prompts** — the top-level frame for chat-style use.
- **RAG sources** — the documents your retrieval layer surfaces to the model.

What unites these is that they're all *deliberate context*: material you've curated specifically to shape the model's behavior.

## Why the category matters

Three years ago "prompt engineering" covered all of this. The phrase has aged poorly because the work is no longer mostly about cleverly worded prompts. The work is about **deciding what context to make available, in what shape, for what scope, with what lifecycle.**

That's a different skill — closer to information architecture than to copywriting.

Once you start treating these artifacts as a category, useful questions appear:

- What's the right size? (Almost always: smaller than your first instinct.)
- What scope — repo, directory, task, session?
- How does it interact with other context the model is seeing?
- How do you keep it from going stale as the project changes?
- How do you test that it's actually doing something?

The rest of this site works through those questions, one resource type at a time.

## Related

- [Context is a budget, not a bucket](/docs/foundations/context-is-a-budget/)
- [Crafting a CLAUDE.md](/docs/per-tool/claude-md/)

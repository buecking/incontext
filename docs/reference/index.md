---
title: Reference
layout: default
nav_order: 6
has_children: true
permalink: /docs/reference/
---

# Reference

Quick lookups. Installable skills, format cheat sheets, directive patterns with empirical evidence, and a diagnostic guide for when something's wrong.

## Pages in this section

- **[Front matter cheat sheet](/docs/reference/front-matter/)** — what each tool's context file expects at the top. CLAUDE.md, SKILL.md, sub-agents, Cursor rules, Aider, Continue.dev, Copilot, Windsurf, AGENTS.md — fields, locations, load behavior, copy-pasteable snippets.
- **[Directives that work](/docs/reference/directives/)** — phrasings that reliably change model behavior, with the papers behind each. The 12 patterns worth using in CLAUDE.md / AGENTS.md / SKILL.md, with explicit notes on which ones backfire on reasoning models.
- **[Failure modes](/docs/reference/failure-modes/)** — diagnostic guide. The 14 documented ways context resources go wrong, what each one looks like in practice, the empirical evidence, a quick test that confirms it, and the standard fix.

## Installable skills

These are raw `SKILL.md` files following the [Agent Skills](https://agentskills.io) open standard — originally developed by Anthropic and supported by 30+ agent tools including Claude Code, Cursor, OpenAI Codex, GitHub Copilot, and Gemini CLI. Point your agent at them or pull them into your repo.

### Install one

Skills live at one of two paths:

```bash
# Per-project (committed to the repo, available to everyone on the team)
.claude/skills/<skill-name>/SKILL.md

# Per-user (available across every project on your machine)
~/.claude/skills/<skill-name>/SKILL.md
```

Pull `xp-programming-workflow` into the current repo:

```bash
mkdir -p .claude/skills/xp-programming-workflow
curl -fsSL https://incontext.info/skills/xp-programming-workflow/SKILL.md \
  -o .claude/skills/xp-programming-workflow/SKILL.md
```

Start a new Claude Code session in that repo and the skill is loaded. Invoke directly:

```
/xp-programming-workflow implement the points-on-lesson-completion story
```

Or describe the task — the skill's `description` field tells the agent when to apply it on its own.

### Available

| Skill | What it does | Install |
|---|---|---|
| [`xp-programming-workflow`](/skills/xp-programming-workflow/SKILL.md) | Runs one XP loop: story → failing test → minimal impl → refactor → atomic commit → reset. Defends against the dumb zone by design. | `curl -fsSL https://incontext.info/skills/xp-programming-workflow/SKILL.md` |

Explainers for each skill live under [Skills](/docs/skills/). The XP workflow has its own page for the [Beck source](/docs/skills/xp-workflow/) and the [AI-team adaptation](/docs/skills/xp-with-ai/).

### Verify a skill is loaded

In any Claude Code session:

```
/skills
```

You'll see the skill listed by name with its description. If it's not there, check the path and the YAML frontmatter — both `name` and `description` should be present.

## Hire us

If you landed here because one of these skills crossed your feed: the work that produced them is what we do for clients. The site is the resume. Reach us at the GitHub link in the header.

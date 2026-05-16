---
title: Skills
layout: default
nav_order: 5
has_children: true
permalink: /docs/skills/
---

# Skills

A **skill** is a reusable, named workflow that an AI coding tool can invoke on demand — `/improve-codebase-architecture`, `/grill-me`, `/simplify`. They're packaged context plus packaged behavior: a small, scoped procedure the model already knows how to run, so you don't have to re-explain it every session.

Skills are a context resource in the sense that [the rest of this site](/docs/foundations/what-is-a-context-resource/) uses the term. They live next to your `CLAUDE.md` and `AGENTS.md` and load on demand instead of on every run, which makes them cheap to keep around and easy to compose.

This is the [procedural-memory layer](/docs/foundations/#the-map) the manifesto named — workflows packaged densely enough that the agent doesn't need them re-explained. There are hundreds of skills floating around; most are noise. The ones below are the small set that earns its slot, with the [XP workflow](/docs/skills/xp-workflow/) as the loop everything else hangs off.

## What's here

- **[The XP workflow](/docs/skills/xp-workflow/)** — a faithful summary of Kent Beck's *Extreme Programming Explained* (1999). The values, the principles, the twelve practices, the lifecycle, the roles. The source the AI variant is built on.
- **[XP with an AI on the team](/docs/skills/xp-with-ai/)** — the spinoff. What changes (and what doesn't) when one of the seats at the table is an AI coding agent. Adapts each practice, names the new failure modes, and ends with a 12-point invariant list you can install as a skill.
- **[Parallel XP with token budgets](/docs/skills/parallel-xp/)** — the N-agent variant of the loop, and the chapter that puts the first deliberate move into the episodic and forward-model slots the foundations page calls empty.
- **[Supporting skills](/docs/skills/supporting-skills/)** — the short list of skills that earn their keep alongside the XP loop: `improve-codebase-architecture`, `grill-me`, `simplify`.

## When a skill is the right shape

A workflow is worth turning into a skill when:

1. **You've run it more than three times.** Below that, you're still figuring out what it should do.
2. **Its inputs are stable.** A skill that needs a wall of context every time you invoke it isn't a skill, it's a prompt template.
3. **It returns a recognizable artifact.** A passing test, a green diff, a PR, a refactor plan. Something you can point at and say "that's what the skill produced."

If a workflow doesn't satisfy all three, leave it as a saved prompt. Skills are for things that have earned a name.

---
title: Supporting skills
layout: default
parent: Skills
nav_order: 3
permalink: /docs/skills/supporting-skills/
---

# Supporting skills
{: .no_toc }

1. TOC
{:toc}

---

The [XP workflow](/docs/skills/xp-workflow/) is the loop. These are the small set of skills that compose with it — the ones worth keeping installed because they earn their slot in the menu repeatedly, not because they sound impressive.

The bar for inclusion here is high on purpose. There are hundreds of skills floating around. The three below cover the moments in the loop where a focused, named procedure beats free-form prompting: **before you write code**, **while you write code**, and **after you write code**.

## `improve-codebase-architecture` — before you write code

**What it does.** Reads the structure of the repo and reports back on the things an agent will struggle with: shallow modules, leaky boundaries, over-coupling, files that are doing five jobs. The output is a refactor plan, not a refactor.

**Why it matters.** The structure of your codebase is the single biggest lever on agent output quality. Agents navigate the same way humans do: shallow modules with twenty small, tightly-coupled files are nearly impossible to test in isolation, and impossible to test means impossible to verify, and impossible to verify means impossible to trust.

The fix is **deep modules** — narrow interfaces that hide a lot of behavior — rather than thin ones that punt every decision up to the caller. This is John Ousterhout's *A Philosophy of Software Design* applied to a codebase that's also being read by an agent.

**When to reach for it.**

- Before starting a new feature in an unfamiliar area of the repo.
- When you notice the agent producing tiny diffs that touch many files. That's a structure problem, not a model problem.
- Quarterly, on the area of the codebase that's seen the most change.

**When not to.** Mid-slice. Don't refactor while you're trying to ship. Note the issue, finish the slice, then run the skill in its own session.

## `grill-me` — before you write code

**What it does.** Inverts the usual prompt direction. Instead of you instructing the model, the model interrogates you about the feature you're about to build. It asks the questions a careful collaborator would ask: edge cases, failure modes, who else is affected, what counts as done, what's explicitly out of scope.

**Why it matters.** The PRD step in the [XP loop](/docs/skills/xp-workflow/) is the most consequential one — a wrong PRD makes every subsequent slice wrong in the same direction. Most of the time the failure isn't that you can't write a PRD; it's that you don't notice the questions you haven't asked yourself yet.

A grilling session surfaces the unasked questions. The conversation history isn't the artifact — the answers you give while being grilled are. They go into the PRD.

**When to reach for it.**

- At the start of a feature, before any slicing.
- After a planning meeting, with the meeting transcript pasted in. The model will ask follow-ups that the meeting didn't.
- Whenever you find yourself writing a PRD and feeling vaguely uncertain. That's the symptom.

**When not to.** During implementation. The grilling skill is good at making you slow down; that's the wrong move once a slice is underway.

## `simplify` — after you write code

**What it does.** Reads a recently-changed diff and looks specifically for accidental complexity: premature abstractions, validation that can't fail, error handling for cases that can't happen, helper functions used once, comments that restate the code. The output is a smaller diff.

**Why it matters.** AI-generated code skews toward more — more layers, more handlers, more "just in case." Each of those is a future maintenance load and a future source of agent confusion. The refactor step in the XP loop is the place to catch this, and `simplify` is the version of the refactor step that has a name.

**When to reach for it.**

- During step 5 of the XP loop, before opening the PR.
- On a PR you're reviewing where the diff feels bigger than the change warranted.
- On any code that has the words "in case" in a comment.

**When not to.** Before tests are green. Simplification with a red bar is just rewriting.

## What's deliberately not on this list

A few skills people expect to see here, and why they aren't:

- **Generic test generators.** They write tests after the code, which gets the [XP loop](/docs/skills/xp-workflow/) backwards. The test is the contract, not the postscript.
- **Documentation generators.** Generated docs go stale faster than they get read. If the code needs explaining, fix the code.
- **Anything with "10x" in the name.** The honest skills don't need the marketing.

The pattern across the three skills above: each one is named for a *moment in the workflow*, not a category of task. That's the test for whether a skill belongs in the menu.

## Related

- [The XP workflow](/docs/skills/xp-workflow/) — the loop these compose into
- [The smart zone and the dumb zone](/docs/foundations/smart-zone-and-dumb-zone/) — why each of these gets its own session

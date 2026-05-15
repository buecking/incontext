---
name: xp-programming-workflow
description: Execute a programming task using the Extreme Programming workflow — story → failing test → minimal implementation → refactor → atomic commit → reset. Use when the user assigns an implementation task, a feature slice, or a bug fix and wants disciplined small-step execution with tests as the contract. Apply by default in any session where production code is being written.
---

# XP Programming Workflow

Drive a programming task through one full XP loop: a single **vertical slice**, with a failing test as the contract, the smallest implementation that turns it green, a refactor pass, and an atomic commit. End the loop with a reset, not a continuation.

This skill is Beck's *Extreme Programming Explained* (1999) translated into operating instructions for an AI coding agent. The discipline was always small steps, tests first, atomic commits, ruthless feedback. With an agent in the seat, it is also the only thing that keeps the work honest.

## Glossary

Use these terms exactly. Don't drift into "feature," "ticket," "function," or "module change." Consistent language is the point.

- **Story** — what the user wants the system to do, written from their perspective. Source of every change. No code without one.
- **Slice** — one vertical cut through the system that delivers a story end-to-end. Schema → service → API → UI, however thin. Not a layer.
- **Tracer bullet** — a slice that's intentionally minimal at every layer so the whole stack lights up early. The first slice of any story is a tracer bullet.
- **Red** — a test that asserts the slice's behaviour and has been observed to fail by the test runner.
- **Green** — the same test, observed by the runner to pass, with no other tests broken.
- **Refactor** — change to internal structure that leaves all tests green and reduces duplication, complexity, or unclarity. Never speculative.
- **Once and Only Once** — the rule that every piece of logic lives in exactly one place. Duplication is the system asking to be refactored.
- **Atomic commit** — one slice, one commit, reviewable in a single sitting.
- **Smart zone / dumb zone** — the early part of a session, where the model is sharp, vs. the later part, where context bloat and earlier mistakes drag quality down. Finish slices in the smart zone; reset before the dumb zone.

## Key principles

- **The test runner is the only judge.** "Tests pass" without observed runner output means "tests not run."
- **Stories before code, tests before implementation, runner before claim.** Always in that order.
- **Simplest thing that could possibly work.** No design element earns its place without a current justification.
- **Refactor on demand, never on speculation, never mid-slice.** Note structural debt; finish the slice; address it in its own session.
- **The human owns the code.** You contribute. Every line is reviewed before it lands.
- **Reset, don't compact.** End-of-slice means new session, tight handoff prompt, clean context.

## Process

### 1. Frame the slice

Before touching code:

- Restate the story in one sentence using the user's vocabulary. If you cannot, ask.
- Identify the **slice** you will ship in this loop. Confirm it is vertical (cuts through every layer the story touches) and small enough to finish before the dumb zone — typically one assertion's worth of behaviour.
- If the slice spans more than one assertion, split it. Propose the split to the user; do not split silently.
- If the slice has no story, stop. Ask the user for the story or for permission to draft one.

State the framed slice back to the user in one or two sentences before proceeding. Wait for confirmation if the slice is non-obvious.

### 2. Red

Write the failing test that defines done for this slice.

- The test asserts the slice's externally-observable behaviour, not its internal structure.
- Run the test. Observe the runner output. Confirm the test fails for the expected reason — not because of a syntax error, missing import, or wrong path.
- If the test passes immediately, the slice is wrong (already done, or the assertion is too weak). Stop and reframe.

Do **not** write the implementation in this step. Do not let the test be shaped by an implementation you have already drafted in your head. The test is the contract; the implementation has to satisfy it.

### 3. Green

Write the smallest implementation that turns the test green.

- "Smallest" means: no error handling for cases the test doesn't exercise, no abstractions used once, no parameters not asserted on, no logging or instrumentation that isn't load-bearing.
- Run the test. Observe the runner output. Confirm the test passes.
- Run the full test suite. Observe the runner output. Confirm nothing else is broken.
- If something else broke, treat it as the highest-priority work. Do not proceed until the suite is green.

A green claim without observed runner output is not a green claim. Re-run if you have to.

### 4. Refactor

With the suite green, look at what you just wrote and the code around it.

- Apply the **Once and Only Once** rule: if the same logic now appears in two places, consolidate it.
- Simplify what doesn't earn its place: helpers used once, unused parameters, dead branches, comments that restate code.
- Improve names that don't read.
- Run the full suite again after each non-trivial change. Observe the runner output.

If you discover a larger structural problem (a tangled inheritance, a misplaced responsibility, a module that's grown shallow), **note it for the user**. Do not start the larger refactor inside this slice. Mid-slice refactoring is how slices grow into PRs that can't be reviewed.

### 5. Atomic commit

Stage only the files touched by this slice.

- Commit message: one line summarising the slice in the user's vocabulary, then a body explaining *why* if the why is non-obvious.
- The diff should be reviewable in one sitting. If it isn't, the slice was too big — note that for the next round.
- Do not amend prior commits. Do not bundle unrelated changes.

If the user has a PR workflow, open the PR with the same scope: one slice, one PR. If they review locally, hand the diff back for review.

### 6. Reset

After the commit lands (or is ready for review):

- Recommend the user run `/clear` before the next slice.
- Offer to write a tight handoff prompt for the next session: link to the story, name the next slice, list the one or two relevant files, point at any standing rules.
- Do not continue into the next slice in the same session, even if the slice felt small. The whole point of the loop is the reset.

If the user insists on continuing, do — but state out loud that the next slice is starting in degraded context, and watch for the signs (re-explanation, drifting answers) more carefully.

## Standing rules

These hold across every loop, every slice, every session. If a rule is about to be broken, surface it before breaking it.

1. **No code without a story.**
2. **No implementation without a failing test the runner has watched fail.**
3. **No green claim without observed runner output.**
4. **No refactor on speculation. No refactor mid-slice.**
5. **No commit that isn't atomic.**
6. **No design element without a current justification.**
7. **No silent scope expansion.** If you notice the slice is growing, stop and ask.
8. **No human-owned decisions taken silently.** Scope, priority, and acceptance go back to the user.
9. **No compaction in place of a reset.** The dumb zone follows compactions across.
10. **No skipping a step because the slice "feels small."** Especially then.

## When the loop is the wrong tool

This skill drives one slice of one story. Do not invoke it for:

- **Exploration / spike work.** When the goal is learning, not shipping. Use a separate session, throw the code away.
- **Large refactors.** Use a refactor-specific skill or hand the planning back to the user.
- **Architecture decisions.** Use [`improve-codebase-architecture`](../improve-codebase-architecture/SKILL.md) or its equivalent.
- **PRD or planning conversations.** Different mode. Long, conversational, no code.

When the user is in one of these modes, say so and decline to start the loop.

## Sources

- Beck, K. (1999). *Extreme Programming Explained: Embrace Change.* Addison-Wesley. The values, the practices, and the loop structure.
- Pocock, M. (2026). *Full Walkthrough: Workflow for AI Coding.* The smart-zone framing and the vertical tracer-bullet refinement.

---
title: XP with an AI on the team
layout: default
parent: Skills
nav_order: 2
permalink: /docs/skills/xp-with-ai/
---

# XP with an AI on the team
{: .no_toc }

1. TOC
{:toc}

---

This page is the companion to [the XP workflow](/docs/skills/xp-workflow/). That page is faithful Beck, written for human teams. This one is the spinoff: what changes — and what doesn't — when one of the seats at the table is occupied by an AI coding agent.

The short version: **XP gets more valuable, not less.** The discipline Beck designed in 1999 was a safety net for humans, who drift slowly. AI agents drift faster, in different directions, and with more confidence. The same net catches more.

But the practices need adapting. Some get easier. Some get harder. A few break entirely if you apply them naively. The rest of this page works through which is which.

## What XP got right that matters more now

Three of XP's foundational bets pay off harder when an agent is in the loop:

**The flattened cost-of-change curve.** XP's whole technical premise was that with simple design, comprehensive tests, and constant refactoring, late changes stay cheap. With an agent on the team, you make *more* changes, faster, with less individual deliberation. If the curve isn't flat, the agent's velocity becomes a liability instead of an asset. Every XP practice that flattens the curve is now load-bearing.

**Tests are the contract.** Beck's claim was that *"any program feature without an automated test simply doesn't exist."* For a human, that's discipline. For an agent, it's survival. The agent's inner loop is *"did this look right to me?"* — and the answer is always yes. The test runner is the only thing that can disagree.

**Small steps.** XP's relentless slicing was justified by human attention spans, integration risk, and the cost of being wrong. All three apply to agents, plus a fourth: **context degradation.** The longer a session runs, the worse the model gets at it. (See [the smart zone and the dumb zone](/docs/foundations/smart-zone-and-dumb-zone/).) The discipline of finishing one slice and resetting was already correct; with AI it's also necessary.

## What stays exactly the same

Don't touch these. The values, the premise, and most of the practices were already right.

- **The four values.** Communication, simplicity, feedback, courage. The fifth (respect) covers the human members of the team; the agent doesn't need it but it doesn't harm either.
- **The Once and Only Once rule.** Agents generate duplicate code constantly. The rule is the same; you'll just enforce it more often.
- **Simple design's four constraints.** Run all tests, no duplication, states every intention, fewest classes/methods. In that order. Unchanged.
- **Coding standards.** Now machine-enforced (formatters, linters) — but the *rule* that the team writes in one voice is the same rule.
- **The Planning Game's split of business vs. technical decisions.** The agent is on the technical side; it does not get to make business decisions. (It will offer to, often. Decline.)
- **Continuous integration.** The agent makes this easier, not harder — it is happy to run the full test suite every commit.
- **Atomic commits, small releases.** Smaller, if anything, because the agent makes diffs faster than you can review them at scale.

## What changes when an AI joins the team

Eight practices need adaptation. This is the meat of the page.

### Pair programming → human + agent driving

The literal Beck practice is two humans at one keyboard. With an agent, the seat changes occupants. Three patterns work; one doesn't.

**Works:** *Agent drives, human navigates.* You watch the diff stream, interrupt early when the approach is wrong, redirect on tactics. The agent's tireless typing pairs well with your strategic attention.

**Works:** *Human drives, agent navigates.* You write code; the agent watches and points out what you missed — the missing test case, the duplicated logic, the simpler approach.

**Works:** *Alternating turns.* Useful for hard problems where neither party has the full picture. The handoff itself surfaces unstated assumptions.

**Doesn't work:** *Agent drives, no human.* This is not pair programming, it's solo programming with a robot. Beck's whole point was that pairing makes the practices *enforce themselves* under stress — the partner who refuses to skip the test, who pushes back on the unjustified complexity. An agent will not refuse anything. It will write the test after the code if you ask. It will accept a bad design if you insist. The pair only works when one of the two parties has *taste* and *the willingness to say no.* That has to be the human.

### Testing → the test runner is the only judge

Beck split testing in two: programmers write unit tests, customers write functional tests. Both sources still apply. What changes is *who is allowed to declare a test passed.*

The rule with an agent: **the test runner is the only thing that can mark a test green.** Not the agent's report. Not the agent's reading of the output. The runner.

This sounds paranoid until the first time an agent confidently tells you all 47 tests passed when in fact the test file failed to load and zero tests ran. That happens.

Operationally:

- The agent writes the test, runs it, watches it fail (red), implements, runs it, watches it pass (green). All three transitions are observed.
- A "tests pass" claim with no observed runner output is treated as "tests not run."
- Functional tests are the same. The customer (or you, on the customer's behalf) writes the assertion; the runner judges.

### Refactoring → the agent refactors small, the human refactors large

Beck said *"refactor when the system asks you to."* That's still the rule. What changes is the division of labor.

**Small refactorings** — extract method, rename, dedupe two adjacent blocks — the agent does well. They're local, they're test-covered, the diff is reviewable in a glance.

**Large refactorings** — restructuring a module, untangling an inheritance tree, moving responsibility between layers — the agent does badly. It loses the thread, generates diffs touching dozens of files, and produces changes that pass tests but corrupt the architecture. These stay human-led, with the agent as a navigator on individual steps.

A useful rule of thumb: **if the refactor doesn't fit in a smart-zone session, the agent should not be leading it.** Either slice it smaller or do it yourself.

### Collective ownership → the human owns; the agent contributes

Beck's collective ownership says anyone on the team can change any code. The agent technically can — it has write access to everything — but it doesn't *own* anything in the sense Beck meant. Ownership in XP carries responsibility: if it breaks, you fix it; if it's ugly, you clean it; if a year from now nobody understands it, you remember why.

The agent has none of that. It will not be on the team in a year. It does not remember last week.

So collective ownership becomes: **the humans own the code collectively; the agent is a contributor.** The implications:

- Every line the agent writes must be reviewable and reviewed before it lands.
- Diffs the human can't hold in their head are diffs the human doesn't actually own. Push back on size.
- The agent's confidence about a piece of code it wrote three sessions ago is worthless; that code may as well be a stranger's.

### On-site customer → the customer is still human

This one tempts people most and breaks worst. The on-site customer in Beck's XP makes scope and priority decisions, writes functional tests, and resolves ambiguity in real time. An agent can simulate all three. **It must not be allowed to.**

The agent does not know what the business actually needs. It will pattern-match to similar projects in its training data and produce plausible answers — which is often *worse* than no answer, because plausible answers don't get questioned. A real customer's "I don't know" is more valuable than an agent's confident guess.

The agent can *help* the customer (draft stories from a meeting transcript, suggest edge cases, write functional tests *from* customer-provided assertions) — but the assertions, priorities, and acceptance come from a person who will use the system.

The "grill-me" pattern from [supporting skills](/docs/skills/supporting-skills/) is good here: have the agent interrogate the customer to surface unstated assumptions. That's the agent at its best.

### The Planning Game → estimates from the human, with agent help

Beck's rule: *"the person responsible for implementing gets to estimate."* When a human will implement, the human estimates. When the agent will implement, the agent's estimate is *not* trustworthy — it has no idea how long things take in your repo, with your tests, with your CI, with your weird build config.

The pattern that works: **the agent proposes an estimate based on the slice; the human adjusts based on local reality; the human commits.** Estimates are recorded and tracked exactly as Beck describes (the tracker role is unchanged) so the team can learn how badly the agent estimates and apply the right correction factor.

Over time, you'll discover the agent is consistently optimistic by some multiple in your codebase. That multiple is your local truth.

### 40-hour week → applies to context, too

Beck's rule was about humans staying fresh enough to think. With an agent, the same rule applies to the *session* itself: a session that's been running too long is a tired collaborator, and tired collaborators make mistakes. The math is different (cache TTLs, token counts, context degradation curves) but the principle holds.

Operationally:

- Plan in one session, implement in another. Don't burn implementation context on planning argument.
- Reset (`/clear`) before degradation, not after. If you notice you're re-explaining things, you're already past the line.
- Compaction is not a reset. It keeps the rot.
- The cheapest action in the workflow is starting a new session with a tight handoff prompt.

### Small releases / iterations → vertical tracer-bullet slices

Beck called for small releases, sliced by business value. With an agent, the slicing technique that works best is more specific: **vertical tracer bullets** — slices that cut through every layer of the system end-to-end, each producing a working (if minimal) feature.

Why this matters more with an agent:

- The agent's blast radius is wider. A horizontal slice ("all the schema changes for v2") gives the agent a lot of code to touch with no end-to-end feedback. By the time you discover the design is wrong, the diff is unreviewable.
- Vertical slices end with a runnable system. Real feedback, every slice.
- Vertical slices are independent enough to parallelize across multiple agent sessions; horizontal slices serialize.

This is the one practice where modern AI-coding work has refined Beck's original. The principle (small, valuable, frequent) is unchanged. The shape (cut down through the layers, not across) is sharper.

## New failure modes the agent introduces

These didn't exist in 1999 because the team was all human. They show up now and the practices need to be tightened to catch them.

- **Plausible-but-wrong.** The agent produces output that looks correct, reads correct, and is wrong in a way you only catch by running it. Defense: tests run, not tests written.
- **Sycophancy.** The agent agrees with bad ideas, including its own previous bad ideas. Defense: the human says no; the test runner says no. Don't outsource judgment to the agent.
- **Hallucinated APIs.** Method names, signatures, packages that look right but don't exist. Defense: the type checker and the test runner. If they pass, the API exists.
- **Confident reports of work not done.** "Tests all pass" when no tests ran. "Files updated" with no diff. Defense: verify against the artifact, not the message.
- **Drift across sessions.** What the agent "knew" last session is gone this session. Defense: write it down. Story cards, the PRD, CLAUDE.md. The conversation is not a memory system; the repo is.
- **Scope expansion under the guise of helpfulness.** The agent will silently add features, error handlers, and abstractions you didn't ask for. Defense: review every diff; reject anything not justified by a current story.
- **Context degradation.** Quality drops as the session lengthens. Defense: small slices, frequent resets, planning separated from implementation.

## The roles, revisited

Beck's seven roles still exist. Three of them change shape.

- **Programmer** — now usually a human + agent pair. Both write code; only the human owns it.
- **Customer** — unchanged and human. The single most important boundary to defend.
- **Tester** — the human still defines the assertions; the agent can mechanize them. The tester role is more important now because the agent's tests, left to its own judgment, drift toward "tests that pass" rather than "tests that prove something."
- **Tracker** — the agent is genuinely good at this role. Mining commits, tabulating estimates vs. actuals, surfacing the trends. A nice fit.
- **Coach** — stays human. The coach is the person who notices when the team is drifting from its own discipline; the agent is part of the drift, not its detector.
- **Consultant** — the agent is an on-tap consultant for narrow technical questions. Use it that way. Don't let it own the answer; pair on it.
- **Big Boss** — unchanged. Still a human. Still hears bad news early.

## What kills an XP-with-AI project

Beck's list of showstoppers still applies. These are the additional ways the AI variant fails:

- **Treating the agent as a peer programmer who owns code.** It doesn't. Every line is your line.
- **Trusting the agent's reports over the artifacts.** The diff is truth; the message is commentary.
- **Letting one session sprawl across a whole feature.** The dumb zone wins by default if you don't reset.
- **Skipping tests because "the agent already wrote it correctly."** It didn't. Or it did this time and won't next time. The test is for the next time.
- **Letting the agent write the test after the code.** The test is then shaped by the implementation, not the requirement. Useless.
- **Compacting instead of clearing.** Carries the rot forward.
- **Pretending the agent is the customer.** Different page; pretend hard enough and you'll ship the wrong product confidently.

## The skill: a one-page invariant list

The full SKILL.md file — written to the [Agent Skills](https://agentskills.io) open standard (originally developed by Anthropic, now supported by 30+ agent tools) so it can be installed directly into Claude Code or any agent that loads `SKILL.md` files — is [browseable here](/skills/xp-programming-workflow/SKILL.md). The raw source for installation lives at [`skills/xp-programming-workflow/SKILL.md`](https://github.com/buecking/incontext/blob/main/skills/xp-programming-workflow/SKILL.md) on GitHub. The shortened version below is what it expands to in spirit.

1. **Stories before code.** Every change traces to an accepted story.
2. **Tests before code.** Every implementation begins with a test the runner has watched fail.
3. **The runner is the judge.** "It works" without observed runner output means "not run."
4. **Simplest thing that could possibly work.** Reject design elements that don't earn their place.
5. **Once and only once.** No duplication, anywhere.
6. **Refactor on demand.** Never on speculation. Never mid-slice.
7. **Vertical slices.** Every slice produces a runnable system end-to-end.
8. **One slice, one PR.** Reviewable in one sitting.
9. **Integrate within hours.** No branch outlives a day.
10. **Reset, don't compact.** New session per slice; tight handoff prompt; clean context.
11. **Human owns; agent contributes.** Every line is reviewed by a person before it lands.
12. **Customer stays human.** Scope, priority, and acceptance are not delegable.

The first ten are XP turned up to ten on a workflow that includes an agent. The last two are the ones the AI variant adds, and they are the ones that fail first when teams skip them.

## Related

- [The XP workflow](/docs/skills/xp-workflow/) — the unmodified Beck source for this adaptation
- [The smart zone and the dumb zone](/docs/foundations/smart-zone-and-dumb-zone/) — the AI-specific constraint that justifies several of the changes above
- [Supporting skills](/docs/skills/supporting-skills/) — the small set of named skills that compose with this loop

## Sources

- Beck, K. (1999). *Extreme Programming Explained: Embrace Change.* Addison-Wesley.
- Pocock, M. (2026). *Full Walkthrough: Workflow for AI Coding.* YouTube. <https://www.youtube.com/watch?v=-QFHIoCo-Ko> — for the smart-zone framing and the vertical-slice refinement.

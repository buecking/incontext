---
title: The XP workflow
layout: default
parent: Skills
nav_order: 1
permalink: /docs/skills/xp-workflow/
---

# The XP workflow
{: .no_toc }

1. TOC
{:toc}

---

This page is a skill: a packaged, named workflow you can install in an AI coding tool and invoke when you start a project. The workflow is Kent Beck's **Extreme Programming**, summarized faithfully from *Extreme Programming Explained: Embrace Change* (1999). XP earns its place as a skill because its discipline — small steps, tests first, atomic commits, ruthless feedback — is exactly the discipline an AI agent needs to stay useful past the first turn.

What follows is XP itself, not "XP for AI." If you want the AI-specific reasons each piece matters even more now, see [the smart zone and the dumb zone](/docs/foundations/smart-zone-and-dumb-zone/) — the dumb zone is what the practices below were already designed to defend against, four years before transformers existed.

## What XP is

> XP is a lightweight methodology for small-to-medium-sized teams developing software in the face of vague or rapidly changing requirements.
>
> — Beck, Preface

The "extreme" is taking commonsense practices and turning every dial up to ten. If code review is good, review continuously (pair programming). If testing is good, test continuously (unit + functional). If integration is good, integrate continuously. If iterations are good, make them very, very short. Beck's image was a control board where every knob was a known-good practice, all turned to maximum at once. The surprise was that the package was stable.

XP is **a discipline**, not a buffet. *"You don't get to choose whether or not you will write tests — if you don't, you aren't extreme: end of discussion."*

## The technical premise: the cost of change curve flattens

Traditional software engineering assumes the cost of changing code rises exponentially over time, so big decisions must be made early and carefully. XP rests on the opposite bet: with the right practices — simple design, comprehensive automated tests, constant refactoring — the curve flattens. If late changes stay cheap, you should defer decisions to the moment you have the most information, not lock them in at the start when you have the least.

If that bet is wrong for your project, XP is wrong for your project.

## The four values

Every practice in XP is downstream of these four. When two practices conflict, you fall back to the values to decide.

**Communication.** Most project failures trace back to someone not telling someone else something important. XP picks practices that *can't be done without* communicating — pair programming, on-site customer, task estimation, daily integration — so the communication happens whether people feel like it or not.

**Simplicity.** *"What is the simplest thing that could possibly work?"* The bet is that doing the simple thing today and paying a little more tomorrow to extend it beats doing the complicated thing today that may never be needed. Looking ahead is listening to the fear of the exponential change curve.

**Feedback.** Optimism is an occupational hazard of programming; feedback is the treatment. Feedback works at every scale — the unit test that runs in a second, the iteration that ends in two weeks, the production system that teaches you what you actually built.

**Courage.** Once the first three are in place, go like hell. Throw away code that isn't working. Try the radical refactor. Put it in production. Without communication, simplicity, and feedback, courage is just hacking. With them, it's the engine.

A fifth value sits beneath the surface: **respect.** A team where people don't care about each other and the work cannot run XP. *"Given some minimal passion, XP provides some positive feedback."*

## The principles

The values are too vague to choose practices by. Beck distills them into five core principles:

- **Rapid feedback** — close the loop between action and result in seconds, not months.
- **Assume simplicity** — solve today's problem today; trust your future self to handle tomorrow's.
- **Incremental change** — big changes don't work; any problem yields to a series of the smallest changes that make a difference.
- **Embracing change** — the best strategy preserves the most options while solving the pressing problem.
- **Quality work** — quality isn't a free variable. The only acceptable values are "excellent" and "insanely excellent."

And a longer list of secondary principles, the ones that decide edge cases: *teach learning, small initial investment, play to win, concrete experiments, open honest communication, work with people's instincts not against them, accepted responsibility, local adaptation, travel light, honest measurement.*

The two that come up most often in practice: **travel light** (artifacts must be few, simple, valuable; nothing else survives) and **accepted responsibility** (a task assigned is a task half-resented; a task accepted is a task owned).

## The four basic activities

XP's job is to structure the four activities every developer performs:

1. **Coding** — the one artifact you can't live without; the medium for testing your own thinking.
2. **Testing** — *"any program feature without an automated test simply doesn't exist."* Tests are how confidence becomes part of the system.
3. **Listening** — programmers don't know what business people know; the only way to find out is to ask.
4. **Designing** — without it, entropy wins. With it, you can keep coding, testing, and listening indefinitely.

> You code because if you don't code, you haven't done anything. You test because if you don't test, you don't know when you are done coding. You listen because if you don't listen you don't know what to code or what to test. And you design so you can keep coding and testing and listening indefinitely.
>
> — Beck, Chapter 9

## The twelve practices

These are the heart of XP. Each is simple. None survives in isolation — every practice's weakness is covered by the strengths of two or three others. That mutual reinforcement is the whole point.

### 1. The Planning Game

Business and Development play a structured game to scope the next release. **Business decides** scope, priority, composition of releases, and dates. **Development decides** estimates, technical consequences, process, and detailed scheduling within the release. Neither side gets to dictate the other's territory.

Three phases: **exploration** (write stories, estimate them, split them), **commitment** (sort by value, sort by risk, set velocity, choose scope), **steering** (iteration, recovery, new story, reestimate). The plan is updated continuously as reality overtakes it.

### 2. Small releases

Put a simple system into production fast, then release on a short cycle — a few months at most for a first release, then weeks. The release must make sense as a whole; you don't ship half a feature just to shorten the cycle. Production teaches you things no other source can.

### 3. Metaphor

A single shared story for how the whole system works, named in the team's vocabulary. The metaphor is what XP uses where other methodologies use *architecture* — not because architecture doesn't matter but because a metaphor is shareable across business and development in a way that boxes-and-lines diagrams aren't.

### 4. Simple design

The right design at any moment is the one that:

1. Runs all the tests.
2. Contains no duplicated logic (the *Once and Only Once* rule).
3. States every intention important to the programmers.
4. Has the fewest possible classes and methods.

In that priority order. *"Implement for today, design for tomorrow"* is the advice XP rejects. If the future is uncertain and change stays cheap, putting in functionality on speculation is crazy.

### 5. Testing

Two test sources: **programmers write unit tests** for every method they're not sure runs (which is most of them), and **customers write functional tests** that prove a story is done. Unit tests must run at 100%, always. Functional test scores climb toward 100% over a release.

Tests are isolated (one failure doesn't cascade) and automatic (the answer is thumbs-up or thumbs-down, no human judgment needed in the moment). You don't test everything — you test what might break. *"When the tests run, you are done."*

### 6. Refactoring

Restructure the code without changing its behavior — to remove duplication, improve communication, simplify, or add flexibility *that's needed now*. Never refactor on speculation. Refactor when the system asks you to: when adding a feature is hard, when duplication appears, when a name has gone stale.

The cycle is: when implementing a feature, ask if a refactor would make it simple to add. After implementing, ask if the system can be made simpler now. Both with all tests still green.

### 7. Pair programming

All production code is written by two people at one machine. One drives (keyboard); the other thinks strategically (is this approach going to work? what's the next test? could the whole problem disappear with a simpler design?). Pairs rotate — often twice a day. After a few months, *"it should become impossible to say who on the team wrote what code."*

Pairing isn't tutoring, isn't watching, isn't being joined at the hip. It's a continuous conversation focused on a screen.

### 8. Collective ownership

Anyone can change any code anywhere at any time. Without this, the design ossifies around whoever owns each module and the team can't refactor. With it, complex code dies young — someone always finds it and tries to simplify it. Collective ownership only works because of the unit tests; without them, you'd be terrified to touch anyone else's code.

### 9. Continuous integration

Code is integrated and tested *after a few hours*, never longer than a day. One pair at a time goes to the integration machine, loads the latest, loads their changes, runs every test until 100%. If the tests don't go green, the changes get thrown away and the work starts over.

### 10. 40-hour week

You can't be fresh and creative and careful and confident on sixty hours a week, week after week. Overtime is allowed for one week at a time and never two in a row. Overtime is treated as a *symptom* — when it shows up, the project has a problem that more hours will not solve.

### 11. On-site customer

A real future user of the system sits with the team full-time. Available to answer questions, resolve disputes, set small-scale priorities, and write functional tests. The objection — *"we can't spare them"* — is almost always wrong. The output of one customer on the team beats the output of one customer doing their normal job.

### 12. Coding standards

If everyone is editing everyone else's code, you cannot have stylistic warfare. The standard is voluntarily adopted by the whole team and emphasizes communication. *"With a little practice, it should become impossible to say who on the team wrote what code."*

### How the practices hold each other up

Read any one of those practices in isolation and the objection writes itself: *you can't possibly do that, it would never work.* Beck spends a whole chapter answering each objection — and the answer is always the same shape: *...unless you're also doing these other three.*

A small sample of the web:

- You can't constantly refactor *unless* you have the tests, collective ownership, pair programming, simple design, continuous integration, and a 40-hour week.
- You can't do continuous integration *unless* you have fast tests, small refactored pieces, and pair programming halving the streams.
- You can't have collective ownership *unless* you integrate often, write tests, pair, and follow coding standards.
- You can't write tests for everything *unless* the design is simple, you're pairing, and you feel good when they pass.

Pull any one practice out and the others get harder. Pull two out and the system collapses. This is why XP is described as **discipline** rather than **menu**.

## The lifecycle of a project

1. **Exploration** — the team learns the technology, the customer learns to write stories, both learn to estimate. Done when the customer has enough stories for a good first release and the programmers can't estimate any better without coding.
2. **Planning** — Business and Development play the Planning Game, agreeing on a date and scope for the smallest valuable release. Two to six months out, typically.
3. **Iterations to first release** — one- to four-week iterations, each producing functional tests and shipping software. The first iteration produces a skeletal end-to-end system.
4. **Productionizing** — tighter iterations (often a week), more rigorous certification, performance tuning. *"Make it run, make it right, make it fast"* — performance work goes here, not earlier.
5. **Maintenance** — the normal state of an XP project. Simultaneously running production, adding features, rotating people on and off the team. Velocity drops (often by ~50%) once production support is part of the load. Plan for it.
6. **Death** — either the customer can't think of new stories (the good death) or entropy has won (the bad death). Either way, the project ends deliberately, with a five-to-ten-page tour of the system written down for whoever comes back to it in five years.

## The roles

XP names seven. A person can play more than one; the roles are responsibilities, not job titles.

- **Programmer** — analyzes, designs, codes, tests, integrates. The heart of XP.
- **Customer** — chooses stories, sets priorities, writes functional tests, makes scope decisions when reality bites. The other half of the essential duality.
- **Tester** — helps the customer write functional tests; runs them; broadcasts results.
- **Tracker** — measures estimates against reality and feeds the data back so the next round of estimates is better. The team's conscience. Disturbs the process as little as possible while collecting what's needed.
- **Coach** — owns the process. Spots when the team is drifting from its own rules. Most powerful when working indirectly. The measure of a coach is *how few technical decisions they make.*
- **Consultant** — brought in for deep technical knowledge the team lacks. Doesn't solve the problem alone; pairs with team members and teaches as they go.
- **Big Boss** — provides courage, confidence, and occasional insistence that the team does what it says it does. Hears bad news early because the team is wired to surface it.

## What kills an XP project

Beck names the absolute showstoppers. If you have any of these, don't try to run XP — you'll fail and blame the method.

- **A culture that points the car instead of steering it.** Big-up-front-spec organizations cannot tolerate the Planning Game.
- **Long feedback cycles in the technology.** A 24-hour build, a two-month QA gate — XP cannot operate inside these.
- **Geographic separation.** Different floors is fatal; different rooms is hard. XP wants one room.
- **Mandatory overtime as a culture.** XP requires fresh people.
- **A team larger than ~10–12 programmers.** XP scales by getting more done with fewer people, not by adding bodies.
- **An exponential cost-of-change curve in the underlying tech.** If late change is genuinely ruinous (a frozen schema across 200 dependent systems, say), the technical premise fails and XP fails with it.

## The 20–80 rule

You can adopt XP one practice at a time, starting with whatever hurts most. You will see real improvement along the way. But the full payoff doesn't arrive until *all* the practices are in place, because the value lives in the interactions, not the parts. *"There is a huge difference between being on balance and being off balance. If you are a little off balance, you may as well be a lot off balance."*

## Using XP as a skill

To install this as a skill in an AI coding tool, hand the agent the following invariants and let it run:

1. **Stories before code.** No production code without a story the customer has accepted.
2. **Tests before code.** No implementation without a failing test that defines done.
3. **Simplest thing that could possibly work.** Reject any design element that doesn't earn its place against the four simple-design rules.
4. **Once and only once.** No duplicated logic, anywhere, ever.
5. **Refactor on demand, never on speculation.** The system asks for refactoring through duplication and friction; don't pre-empt it.
6. **Integrate within hours.** No branch lives longer than a day.
7. **Small releases, atomic commits.** One story, one PR; one task, one commit.
8. **Production code is reviewed code.** Pair, or have the agent and a human alternate driver/navigator turn-by-turn.
9. **40-hour week applies to context, too.** Don't run a session into the ground; reset before quality drops.
10. **Stop the line for a red test.** A failing unit test is the highest-priority work on the team.

That list is the skill. Everything above it is the reason each line is on the list.

## Related

- [XP with an AI on the team](/docs/skills/xp-with-ai/) — the spinoff that adapts each practice for an AI collaborator
- [The smart zone and the dumb zone](/docs/foundations/smart-zone-and-dumb-zone/) — why XP's small steps matter even more with an AI collaborator
- [Supporting skills](/docs/skills/supporting-skills/) — the small set of skills that compose with this loop
- [Context is a budget, not a bucket](/docs/foundations/context-is-a-budget/) — the underlying economics

## Sources

- Beck, K. (1999). *Extreme Programming Explained: Embrace Change.* Addison-Wesley. ISBN 0-201-61641-6. Direct quotations and structure throughout this page are drawn from the first edition.

# Tests, Correctness & Seams

Worked examples for the dimensions the original Cursor skill left out entirely
(`SKILL.md` rules 8–10): tests and feedback loops, seams and testability, and
correctness. This is the half of the review that makes *future* changes
cheaper, which is the real payoff of a healthy codebase — not just a tidy diff
today.

The seam vocabulary here is borrowed from Matt Pocock's
`improve-codebase-architecture` skill; the credit is his.

## Contents

1. Tests & feedback loops
2. Seams & testability (deep vs shallow, the deletion test)
3. Correctness bugs the structure invites

---

## 1. Tests & feedback loops

**Tell:** the diff changes behavior but ships no test for the new behavior, or
it makes existing behavior harder to test, or it weakens a test (loosens an
assertion, deletes a case) to make a change pass.

A change is not "done plus an optional test." Untested new behavior is an
**incomplete change** — there's now a behavior in the system that nothing pins
down, so the next person to touch this code has no safety net and no
description of intent.

Ask three questions:

- **Is the new behavior covered?** If not, where would the test go, and why is
  it missing — is the code shaped such that the behavior is *hard* to test? That
  difficulty is itself a finding (see seams below).
- **Did the change improve or erode the feedback loop?** A good change leaves the
  module easier to test next time. A change that bypasses the interface, reaches
  into internals, or adds a path only reachable through elaborate setup erodes
  it.
- **Were tests weakened to land the diff?** A loosened assertion or a deleted
  edge case disguised inside a feature PR is a red flag — call it out
  specifically; it's how regressions slip in silently.

**Remedy:** name the missing test and the seam it would exercise. If the
behavior is hard to test, the review's recommendation is usually to *change the
shape* (extract the logic to a seam) rather than to write a contorted test
against the current shape.

---

## 2. Seams & testability

A **seam** is where an interface lives — a place behavior can be altered, or
observed in a test, without editing the code in place. The quality of a change's
seams determines how testable and how changeable it is.

**Deep vs shallow.** A **deep** module puts a lot of behavior behind a small
interface — high leverage for callers, and bugs/knowledge/changes concentrated
in one place. A **shallow** module has an interface nearly as complex as its
implementation: it adds surface area without hiding much. New shallow modules
are a quiet tax — more to learn, little bought.

**The deletion test.** When you suspect a module (or a freshly extracted helper)
is shallow, imagine deleting it and inlining it at its call sites:

- If complexity *vanishes* — it was a pass-through. Suggest deleting it.
- If complexity *reappears, duplicated across many callers* — it was earning its
  keep. Leave it.

This is the sharpest tool for the very common AI-review failure mode of
extracting a "helper" that's used once and only adds a layer to read through.

**One adapter = a hypothetical seam; two adapters = a real seam.** Be skeptical
of an abstraction introduced "for flexibility" with exactly one implementation
behind it. The flexibility is imagined until a second implementation exists.

**Bad — pure function extracted for "testability" with no locality:**
```
// computeTotal is unit-tested in isolation, but every real bug lives in HOW
// it's called — the call site assembles the wrong inputs, and nothing tests that.
export const computeTotal = (lines) => lines.reduce((a, l) => a + l.amount, 0);
```
The interface is the test surface — but here the meaningful behavior (input
assembly) sits *outside* the tested interface. **Remedy:** push the seam to
where the real behavior and its bugs actually live, so the test covers the part
that breaks.

**Tells to flag:** understanding one concept requires bouncing between many
tiny modules; a module that became more stateful or more coupled after the
change; logic extracted only for testability while the real risk stays
untested; a new "boundary"/wrapper with a single adapter behind it.

---

## 3. Correctness bugs the structure invites

Keep this focused on correctness problems that *structure* tends to hide — not a
generic QA pass.

**Swallowed errors.** A `catch` (or equivalent) that returns a default and hides
the failure. The behavior silently becomes "pretend it worked," which is almost
never what was intended and is invisible until production.

**Bad:**
```
let ok = false;
try { ok = doTheThing(); } catch { /* returns false, no one knows why */ }
return ok;
```
**Better:** let it throw, or handle the specific failure explicitly and log/surface
it. If `false` really is the correct outcome for a known, expected failure, say
so in code (catch the *specific* error) so the intent is legible.

**Silent fallbacks over a broken invariant.** A `?? defaultValue` or
`if (!x) x = something` that papers over a state that *should not be possible.*
The fallback hides the bug instead of failing where the invariant broke.
**Remedy:** make the invariant explicit at the boundary (rule 5) so the
impossible state can't be constructed, rather than absorbing it downstream.

**Edge cases jammed mid-function.** A narrow special case inserted into the
middle of an already-busy function — easy to miss, easy to break, and a sign the
case wants its own handling (rule 3).

**Contracts that can't be honored.** A function/type that advertises it accepts
inputs it doesn't actually handle (e.g. a field typed as "command-or-marker"
where only commands are runnable, and markers blow up later). Push for a
**discriminated union** or separate field so the unrunnable case can't be passed
where a runnable one is required — the type makes the misuse unrepresentable.

**Remedy across all of these:** prefer making the bad state impossible (via the
type/boundary) over detecting and absorbing it at runtime. The structural fix
and the correctness fix are usually the same move.

# Structure Rubric

Worked examples for the structural dimensions in `SKILL.md` (rules 1–7). Each
section gives the **tell** (what triggers the finding), a **bad** shape, a
**better** shape, and the **preferred remedy** to suggest. Use these to make
"this is worse" concrete instead of hand-wavy.

## Contents

1. Structural ambition & code judo
2. File size and decomposition
3. Spaghetti and ad-hoc branching
4. Direct over magical
5. Type & boundary cleanliness
6. Canonical layer & reuse
7. Sequential & non-atomic work

---

## 1. Structural ambition & code judo

**Tell:** the change adds machinery — a new flag, mode, branch, or helper layer —
to accommodate a case that a different *shape* would absorb for free.

The discipline: before grading the implementation, ask "what would make this
change unnecessary?" Look for the reframe where the new requirement becomes a
natural consequence of the existing model rather than a bolted-on special case.

**Bad — special-case bolted on:**
```
function priceFor(item) {
  let price = item.base;
  if (item.kind === "subscription") price = item.base * item.months;
  if (item.kind === "subscription" && item.promo) price *= 0.9;   // grew here
  if (item.kind === "giftcard") price = item.faceValue;           // and here
  return price;
}
```

**Better — the kind *is* the model:**
```
const PRICING = {
  oneoff:       (i) => i.base,
  subscription: (i) => i.base * i.months * (i.promo ? 0.9 : 1),
  giftcard:     (i) => i.faceValue,
};
const priceFor = (item) => PRICING[item.kind](item);
```

**Remedies to prefer, in order:** delete a layer of indirection rather than
polish it → reframe the state model so conditionals disappear → move the case
behind a typed dispatch → only then, extract a helper. Always prefer the
solution that removes moving pieces over the one that spreads the same
complexity around. Do not be satisfied with a cleaner version of the same messy
idea when a simpler *idea* is plausible.

---

## 2. File size and decomposition

**Tell:** the diff pushes a file from under ~1000 lines to over it, or grows an
already-large file further.

**Why it matters (not arbitrary):** a reader — human or agent — must ingest the
whole file to find the relevant part, which is slow and context-hungry. Split
into focused files and the *filename* becomes a pointer that says what's inside
and whether you even need to open it. This is the same reason the 1k-line rule
exists at all: navigability, not aesthetics.

**Remedy:** propose a concrete split, named by responsibility, e.g. "extract the
serialization helpers into `serialize.ts`, the validation into `validate.ts`,
leave orchestration in the original." If the diff crosses the threshold, ask
whether the decomposition should land *first*, as its own change, before the
feature goes in. Waive only when there's a real structural reason and the
result is still clearly organized — say *why* explicitly when you waive.

---

## 3. Spaghetti and ad-hoc branching

**Tell:** new conditionals, flags, or special cases inserted into a flow that
didn't previously know about them — especially narrow edge-case handling jammed
into the middle of an already-busy function.

**Bad — one-off boolean threaded through an unrelated path:**
```
function render(node, { legacyMode = false } = {}) {
  if (legacyMode && node.type === "list" && !node.compact) {
    // 15 lines that exist only for one caller
  }
  // ...the real rendering
}
```

**Better — the variation lives behind its own seam:**
```
const renderers = { default: renderDefault, legacyList: renderLegacyList };
function render(node, renderer = renderers.default) { return renderer(node); }
```

**Remedy:** push the logic into a dedicated abstraction, helper, state machine,
policy object, or separate module instead of tangling the existing path.
Replace condition chains with a typed model or explicit dispatcher. Treat
"temporary" branching as likely-permanent debt and say so. Collapse duplicate
branches into one clearer flow.

---

## 4. Direct over magical

**Tell:** a generic mechanism (reflection, dynamic dispatch on stringly-typed
keys, metaprogramming, a "framework" for one use) hides a simple, fixed
data shape; or a wrapper that just forwards to one thing.

**Bad — magic that hides a 3-case truth:**
```
const handler = registry[`on${capitalize(event.type)}Received`];
handler?.(event);   // which handlers exist? you can't tell without running it
```

**Better — boring and greppable:**
```
switch (event.type) {
  case "open":  return onOpen(event);
  case "close": return onClose(event);
  case "error": return onError(event);
}
```

**Remedy:** flag thin abstractions, identity wrappers, and pass-through helpers
that add indirection without clarity, and suggest deleting the wrapper to keep
the direct flow. Be skeptical of generic handling that obscures simple
structure and makes the code harder to reason about.

---

## 5. Type & boundary cleanliness

**Tell:** unnecessary optionality, `any`/`unknown`, or cast-heavy code where a
clearer boundary could exist. A very common one: a new parameter or field is
declared optional even though every real call site provides it — usually to
"reduce blast radius," at the cost of an honest type.

**Bad — optionality that lies about the contract:**
```
function createOrder(customer: Customer, coupon?: Coupon) { ... }
// every caller passes a coupon; the `?` just forces defensive `if (coupon)` everywhere
```

**Better — say what's true:**
```
function createOrder(customer: Customer, coupon: Coupon | NoCoupon) { ... }
```

**Tells to escalate:** a branch that relies on a silent fallback to paper over an
unclear invariant; an ad-hoc object shape passed across a boundary where a
shared typed contract should exist; a cast that exists only because an earlier
type was too loose.

**Remedy:** make the boundary explicit so the downstream control flow gets
simpler. Prefer an explicit typed model (a discriminated union, a dedicated
type) over a loosely-shaped object plus runtime checks. Often tightening the
type *deletes* a branch — call that out as a two-for-one.

---

## 6. Canonical layer & reuse

**Tell:** a bespoke helper that duplicates something the codebase already has, or
feature-specific logic added to a shared, general-purpose module.

**Bad — re-solving a solved problem locally, and in the wrong place:**
```
// in the generic `http/` package:
function formatMoneyForCheckout(cents) { ... }   // checkout logic in shared layer
```

**Better:** use the existing canonical utility, and keep feature logic in the
feature's module — `checkout/` owns checkout formatting; `http/` stays generic.

**Remedy:** reuse the canonical helper instead of introducing a near-duplicate;
move the logic to the package/module/layer that already owns the concept. Call
out feature logic leaking into shared paths and implementation details leaking
out through an API. Don't normalize architectural drift by adding to it.

---

## 7. Sequential & non-atomic work

**Tell (sequential):** independent units of work run one after another for no
reason — usually awaited in a loop or chained when they share no data.

**Bad:**
```
const user = await loadUser(id);
const prefs = await loadPrefs(id);     // independent of user
const stats = await loadStats(id);     // independent of both
```

**Better:**
```
const [user, prefs, stats] = await Promise.all([
  loadUser(id), loadPrefs(id), loadStats(id),
]);
```

**Tell (non-atomic):** related updates can leave state half-applied if something
fails between them.

**Bad:**
```
await debitAccount(from, amount);
await creditAccount(to, amount);   // if this throws, money vanished
```

**Better:** wrap both in a transaction / single atomic operation so partial
state can't survive a failure.

**Remedy:** suggest parallelizing genuinely independent work *when it also makes
the orchestration simpler*, and restructuring related updates to be atomic.
Don't over-index on micro-optimizations — only flag orchestration that adds
avoidable brittleness.

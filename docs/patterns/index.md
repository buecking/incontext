---
title: Patterns
layout: default
nav_order: 4
has_children: true
permalink: /docs/patterns/
---

# Patterns

Recurring shapes for organizing context that earn their keep across tools and models. Each page below covers one pattern: what it is, when to reach for it, how to apply it, and where it breaks. Grounded in the official docs of the tools that implement them and in the published research behind the claims.

## In this section

- **[Scope by directory](/docs/patterns/scope-by-directory/)** — let the filesystem carry the layering. Rules close to the code they constrain, not stuffed into one root file. Implemented by every major tool.
- **[Layered context](/docs/patterns/layered-context/)** — global → project → task, with closer-wins overrides. The cache-economics view of why this ordering matters.
- **[Role + task + constraints](/docs/patterns/role-task-constraints/)** — the three-part frame for a system prompt or CLAUDE.md. Including what role *does not* reliably do on modern models.
- **[Retrieve before generate](/docs/patterns/retrieve-before-generate/)** — when retrieval beats stuffing, and the empirical state of the art (Anthropic Contextual Retrieval, 49–67% top-20 failure reduction).
- **[Cite, don't summarize](/docs/patterns/cite-dont-summarize/)** — point at the file instead of paraphrasing it. Citations stay fresh; paraphrases go stale.
- **[Negative examples](/docs/patterns/negative-examples/)** — counter-examples work only when paired with the positive alternative. The empirical case against bare prohibitions.

## How these compose

The six patterns aren't independent — they pull on each other:

- **Scope by directory** is a special case of **layered context**: directory depth is one axis of layering, alongside global/project/task.
- **Role + task + constraints** maps onto **layered context**: role and constraints in the project layer (CLAUDE.md), task in the task layer (user message or perception working set).
- **Cite, don't summarize** is what makes **scope by directory** work: a top-level file that *cites* the subtree-level files stays small and stable; one that summarizes them goes stale.
- **Retrieve before generate** is the external-corpus counterpart to **cite**: when the corpus is large enough that you can't cite it all, retrieve.
- **Negative examples** is the one pattern with a strict pairing rule — it works *inside* the other patterns when used carefully, and breaks badly when used alone.

If you build a context resource that follows all six, the [Perception over history](/docs/foundations/perception-over-history/) layering is what you end up with regardless of intent. The patterns are the local choices; perception is what they look like in aggregate.

---
title: Long-context degradation
layout: default
parent: Foundations
nav_order: 3
permalink: /docs/foundations/long-context-degradation/
---

# Long-context degradation
{: .no_toc }

1. TOC
{:toc}

---

## The short version

Modern models advertise context windows of 200K, 1M, even 2M tokens. **Performance does not stay flat across that window.** Information placed in the middle of a long context is used worse than information placed at the beginning or the end — sometimes dramatically worse.

This is the most-cited failure mode of long context, and the most important one to internalize before you start "just dumping it all in."

## Where the term comes from

The phrase "lost in the middle" comes from a 2023 paper by Nelson Liu and colleagues at Stanford: *Lost in the Middle: How Language Models Use Long Contexts.* Co-authors included Kevin Lin, John Hewitt, Ashwin Paranjape, Michele Bevilacqua, Fabio Petroni, and Percy Liang.

The contribution wasn't the intuition — researchers had suspected long contexts behaved unevenly — but the experimental design that made it concrete. The team placed a single relevant document at different positions in a long context and asked the model questions whose answers depended on that document. They varied only the *position* of the relevant document.

The result was a clean U-shape. Accuracy was high when the relevant material sat near the start of the context, high when it sat near the end, and noticeably lower when it sat in the middle. Same model, same question, same supporting material — only the position changed.

That U-shaped curve became the reference image for the problem, and "lost in the middle" became the standard shorthand.

## What it means in practice

A few rules of thumb that fall out of this finding:

- **Front-load the instruction.** What you want the model to do goes at the top.
- **Repeat the critical bit at the end.** If something is essential to getting the right answer, restating it after the bulk material is cheap insurance.
- **Don't bury the lede.** If you have a 50-page document and the key paragraph is on page 27, the model will struggle to use it even with the full document in context. Lift the key paragraph out and place it explicitly.
- **Order retrieved chunks by relevance, not by document order.** If your retrieval layer is returning 8 chunks, putting the highest-scoring one in the middle is the worst position.

{: .tip }
> When in doubt, treat your context like a sandwich: instruction on top, critical reference at the bottom, bulk material in the middle where it can be skimmed but isn't load-bearing.

## What's changed since 2023

The U-shape has been **replicated repeatedly** across newer and larger-context models. It's gotten less severe in some cases — frontier models in 2025 and 2026 show flatter curves than the 2023 generation — but it has not gone away. Anyone telling you long-context attention is "solved" is selling something.

There's no consensus on the underlying cause. Candidate explanations include:

- Positional encoding artifacts (the math the model uses to track *where* tokens are in the sequence)
- Training-data distribution effects (in natural text, important information clusters near the start and end of documents, so the model has more practice attending there)
- Attention head specialization (some heads track recency, some track the start, fewer track the middle)
- Some interaction of all three

The practical upshot is the same regardless: **position in context is a real variable**, and you should design context resources with that in mind.

## Related

- [Context is a budget, not a bucket](/docs/foundations/context-is-a-budget/) — the broader argument for treating context as a scarce resource
- [What is a context resource?](/docs/foundations/what-is-a-context-resource/) — the vocabulary

## Sources

- Liu, N. F., Lin, K., Hewitt, J., Paranjape, A., Bevilacqua, M., Petroni, F., & Liang, P. (2023). *Lost in the Middle: How Language Models Use Long Contexts.* arXiv:2307.03172.

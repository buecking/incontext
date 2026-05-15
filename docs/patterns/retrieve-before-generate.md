---
title: Retrieve before generate
layout: default
parent: Patterns
nav_order: 4
permalink: /docs/patterns/retrieve-before-generate/
---

# Retrieve before generate
{: .no_toc }

1. TOC
{:toc}

---

When the context the model needs is large, *retrieve the relevant chunks at generation time* rather than stuffing the whole corpus into every prompt. This is the retrieval-augmented generation (RAG) pattern, and the empirically strongest version of it as of 2025 is Anthropic's **Contextual Retrieval** — which reduces top-20 chunk retrieval failure by **49%** over standard RAG.

This page covers when to use retrieval, when to skip it, and the specific configuration that the published evidence supports.

## When retrieval beats stuffing

Three signals that you should put a retrieval step in front of generation:

1. **The corpus is much larger than the working window.** A repo with 100K files, a documentation site with 10,000 pages, a codebase whose total token count exceeds 1M.
2. **Any single task touches a small, identifiable subset.** Most coding tasks touch fewer than 50 files. Most support questions are answered by 1–5 docs. If you can predict the subset, retrieval works.
3. **The corpus updates faster than you want to re-ingest it.** Live documentation, fast-moving codebases, growing knowledge bases. Putting it in the system prompt means re-uploading on every change; retrieval keeps the corpus external.

If all three are true, retrieve. If even one is missing, consider [citing the file directly](/docs/patterns/cite-dont-summarize/) or just stuffing — context windows are large enough now that small corpuses fit comfortably.

## When retrieval *loses* to stuffing

Three counter-signals:

- **The corpus is small enough to fit comfortably in context.** Anything under ~50K tokens usually wins from being included whole. Retrieval's overhead — embedding the query, similarity search, chunk assembly — costs latency for no quality gain.
- **The reasoning requires cross-chunk synthesis.** RAG works when the answer is *in* one of the top-k chunks. When the answer requires synthesizing across 50 chunks, you're better off feeding the model the whole document.
- **Recency matters more than similarity.** Vector similarity has no notion of "current version." A chunk saying "we use Postgres" and a chunk saying "we migrated to ScyllaDB" both score highly on a Postgres question. The model picks one — usually wrong.

See [failure modes §1 — lost in the middle](/docs/reference/failure-modes/#1-lost-in-the-middle) for what happens when retrieval ordering is wrong.

## The empirical landscape

Standard RAG — chunk the corpus, embed each chunk, similarity-search at query time — has known weaknesses. Chunks lose context when extracted: a chunk saying *"The company's revenue grew by 3% over the previous quarter"* doesn't say which company or which quarter, and so doesn't retrieve well on queries that reference those.

Anthropic's [Contextual Retrieval](https://www.anthropic.com/news/contextual-retrieval) (September 2024) addresses this by prepending a model-generated context summary to each chunk before embedding it. The chunk becomes:

> *"This chunk is from ACME Corp's Q2 2024 earnings report comparing to Q1 2024. The company's revenue grew by 3% over the previous quarter."*

Measured improvements over standard RAG:

| Configuration | Top-20 retrieval failure rate | Reduction |
|---|---|---|
| Standard RAG | 5.7% | — |
| + Contextual Embeddings | 3.7% | **35%** |
| + Contextual Embeddings + Contextual BM25 | 2.9% | **49%** |
| + Reranking | 1.9% | **67%** |

Cost to generate the contextualized chunks with Claude and prompt caching: **$1.02 per million document tokens**, one-time.

This is the current empirical bar. If you're building retrieval into a production agent and not using contextual embeddings + BM25 + reranking, you're leaving measurable quality on the table.

## How to apply it

The minimum viable retrieval pipeline:

```text
1. CHUNK     — split corpus into ~500-token chunks with overlap
2. CONTEXT   — for each chunk, generate a 50-100 token contextual prefix
3. EMBED     — embed (prefix + chunk) into a vector store
4. INDEX     — also add (prefix + chunk) to a BM25 index
5. RETRIEVE  — at query time, hybrid-search (vector + BM25), top-150
6. RERANK    — pass the 150 through a reranker, take top-20
7. GENERATE  — pass top-20 to the model with the user query
```

Steps 1–4 are one-time per document (or per document version). Steps 5–7 happen on every query.

The exact prompt Anthropic uses to generate the contextual prefix is documented in the [Contextual Retrieval announcement](https://www.anthropic.com/news/contextual-retrieval) and worth lifting directly.

## Ordering: the lost-in-the-middle constraint

Once you have your top-20 chunks, **order matters**. Liu et al. 2023 ([arXiv:2307.03172](https://arxiv.org/abs/2307.03172)) showed that information in the middle of long context is used worse than information at the start or end. Multi-document QA accuracy traces a clean U-shape over position.

Translation: don't pass the reranker's top-20 to the model in rank order. The most-relevant chunk should be at position 1 *and* either position 20 or just before the user query. The duplicate-at-edges trick is cheap and the evidence behind it is solid.

For long-document tasks, also follow Anthropic's official guidance:

> "Put longform data at the top: Place your long documents and inputs near the top of your prompt, above your query, instructions, and examples. This can significantly improve performance across all models. Queries at the end can improve response quality by up to 30% in tests."
> — [Anthropic prompting best practices](https://platform.claude.com/docs/en/docs/build-with-claude/prompt-engineering/claude-prompting-best-practices)

That's a published, measured 30% improvement for the right ordering.

## How retrieval and perception interact

If you're maintaining a [perception.md](/docs/foundations/perception-over-history/), retrieval and perception serve different layers:

- **Perception** is the agent's *internal* model of the current task — the working memory.
- **Retrieval** is *external* lookup against a corpus the agent doesn't carry.

The two compose. Perception captures "what's true for this slice"; retrieval answers "what does the corpus say about X." If the corpus is mostly internal (your own codebase) and the agent already has a working perception, retrieval is often unnecessary — the perception names the relevant files and the agent reads them directly via tools.

Retrieval earns its keep when the corpus is genuinely external and large: dependency documentation, customer support history, regulatory filings. For "the codebase the agent is already editing," tool-based file reading usually beats embedding-based retrieval.

## Failure modes

- **Embedding similarity ignores version.** A 2020 doc and a 2025 doc on the same topic both retrieve. Solution: prefer metadata-based filtering for time-sensitive corpora; add date to the contextual prefix.
- **Top-k cut at the wrong number.** Too few chunks misses the relevant one; too many dilutes attention. Anthropic's measurement used top-20 *after* reranking, with the reranker reading top-150. Don't skip the reranker step.
- **Middle chunks under-attended.** Even with a perfect retriever, the lost-in-the-middle effect hits ordering. See [failure modes §1](/docs/reference/failure-modes/#1-lost-in-the-middle).
- **Treating RAG as a replacement for working memory.** RAG is for static external corpora. For the agent's working memory across a long task, see [perception over history](/docs/foundations/perception-over-history/).

## Related

- [Cite, don't summarize](/docs/patterns/cite-dont-summarize/) — when to reference vs. retrieve
- [Perception over history](/docs/foundations/perception-over-history/) — the internal-state counterpart to retrieval's external lookup
- [Long-context degradation](/docs/foundations/long-context-degradation/) — why stuffing breaks past a point
- [Failure modes §1 — lost in the middle](/docs/reference/failure-modes/#1-lost-in-the-middle)
- [Anthropic — Contextual Retrieval](https://www.anthropic.com/news/contextual-retrieval) — the empirical reference for this page

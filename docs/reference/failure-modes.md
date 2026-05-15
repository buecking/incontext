---
title: Failure modes
layout: default
parent: Reference
nav_order: 3
permalink: /docs/reference/failure-modes/
---

# Failure modes
{: .no_toc }

1. TOC
{:toc}

---

A diagnostic guide. The agent is doing something wrong — what's wrong with your context?

Each failure mode below has a definition, a symptom you'd actually see, the empirical evidence, a quick test that confirms it, and the standard fix. Use the table to jump to whichever symptom matches.

{: .note }
> Most production context failures are one of three things: **lost in the middle**, **stale instructions**, or **prompt injection**. If you're debugging, check those first.

## At a glance

| Symptom | Likely failure | Section |
|---|---|---|
| Agent ignores a rule that's clearly written down | Stale instructions, or lost in the middle | [§1](#1-lost-in-the-middle), [§3](#3-stale-instructions) |
| Agent reinvents a helper that exists in pasted context | Lost in the middle | [§1](#1-lost-in-the-middle) |
| Quality drops late in a long session | Context bloat | [§2](#2-context-bloat--token-budget-exhaustion) |
| Agent "fights" the actual code | Stale instructions or aspirational rules | [§3](#3-stale-instructions), [§5](#5-aspirational-rules) |
| Inconsistent behavior across runs of the same task | Instruction conflict | [§4](#4-instruction-conflict) |
| Output reads like a design doc when you asked for a fix | Over-specified context | [§6](#6-over-specified-context) |
| Agent agrees with whatever you suggest | Sycophancy | [§7](#7-sycophancy--agreement-bias) |
| Agent does something wild right after a fetch/read | Prompt injection | [§8](#8-prompt-injection-from-context-sources) |
| Output matches example shape even when wrong | Format anchoring | [§9](#9-format-anchoring) |
| Forbidden behavior keeps appearing | Negation failure | [§10](#10-negation-failures) |
| Mid-session, an early rule silently dies | Recency bias | [§11](#11-recency-bias) |
| Behavior degrades after `/compact` | Repetition collapse, or stale-after-compact | [§12](#12-repetition-collapse) |
| Agent hallucinates a tool call or claims to have run something it didn't | Capability mismatch | [§13](#13-capability-mismatch) |
| Agent does unexpected things after installing an MCP server | Tool poisoning | [§14](#14-tool-poisoning-mcp) |

## 1. Lost in the middle

**What.** Information placed mid-context is used worse than information at the start or end, even within the model's nominal window.

**Symptom.** The agent reinvents a function defined in the middle of a pasted file. It quotes the first and last items in a list while behaving as if middle items don't exist. CLAUDE.md sections in the middle are silently dropped.

**Evidence.** Liu et al. 2023 ("Lost in the Middle," [arXiv:2307.03172](https://arxiv.org/abs/2307.03172), TACL 2024). On 20-document multi-doc QA, GPT-3.5-Turbo recall dropped from **~75% (first position) to ~52% (middle)**. Replicated across Claude 1.3, MPT, LongChat. The 16k-context variant didn't eliminate the U-shape.

Updated picture: NoLiMa (Modarressi et al. 2025, [arXiv:2502.05167](https://arxiv.org/abs/2502.05167)) re-ran the eval with one-hop reasoning required, and even frontier models with 128k–1M nominal windows lose **50%+ of short-context accuracy by ~32k tokens**. The middle penalty is reduced in 2025 frontier models but reasoning over middle content is still measurably worse.

**Diagnose.** Put the same unique sentinel sentence at the 10%, 50%, and 90% positions of your context in three separate runs. Ask the agent to retrieve and use it. Variation across positions confirms the failure.

**Fix.**

- Move load-bearing instructions to the start or end of context.
- Trim irrelevant middle content.
- For RAG, re-rank so the top hit is duplicated at the edges.
- In CLAUDE.md, put the most-violated rules near the top.

## 2. Context bloat / token budget exhaustion

**What.** Performance degrades as context length grows, even below the model's window limit and even when everything in it is relevant.

**Symptom.** The agent gets noticeably dumber late in a long session — forgets earlier decisions, repeats fixed bugs, ignores constraints it followed earlier. Tool-call accuracy drops; it picks the wrong file to edit.

**Evidence.** RULER (Hsieh et al. 2024, [arXiv:2404.06654](https://arxiv.org/abs/2404.06654)) measured effective context length on long-context models. Llama-3-70B-Instruct's effective length is **~32k against an advertised 128k** under their threshold. LongBench v2 (Bai et al. 2024, [arXiv:2412.15204](https://arxiv.org/abs/2412.15204)) shows similar degradation curves. Anthropic's own "context engineering" engineering posts (2024–2025) report measurable degradation in tool-selection accuracy as context grows.

**Diagnose.** Run the same task at the start of a fresh session vs. after 50k+ tokens of accumulated history. If quality drops on identical prompts, you have bloat.

**Fix.**

- Compact aggressively (`/compact` in Claude Code, summarization in Cursor).
- Push exploration into sub-agents so their raw output never enters the parent context.
- Move static reference material out of CLAUDE.md into files the agent reads on demand.
- Reset (`/clear`) at slice boundaries instead of running one session for a whole feature.

## 3. Stale instructions

**What.** CLAUDE.md / AGENTS.md / `.cursor/rules/` describes a codebase state that no longer exists.

**Symptom.** The agent "fights" the actual code: insists on import paths that were renamed, generates against deleted helpers, references commands (`pnpm test`) when the repo has migrated (`bun test`). It will sometimes "correct" working code to match the stale instructions.

**Evidence.** Practitioner consensus rather than a single paper; documented in Anthropic's *Claude Code Best Practices* post and in many post-mortems from the Cursor and Aider communities. The mechanism is well-understood: instruction-tuned models weight explicit imperative text heavily relative to inferred conventions, so a stale imperative beats live evidence.

**Diagnose.** Grep CLAUDE.md for commands, paths, and library names. Confirm each still exists. Compare the file against `package.json`, `Makefile`, and actual imports.

**Fix.** Treat CLAUDE.md as code:

- Review it in PRs.
- Lint commands against `package.json` / `pyproject.toml`.
- Regenerate periodically with `/init`.
- Keep it short — staleness scales with size.

## 4. Instruction conflict

**What.** Two context sources contain contradictory rules (CLAUDE.md says tabs, `.editorconfig` says spaces; AGENTS.md says "always write tests first," a system prompt says "minimize unrequested work").

**Symptom.** Inconsistent behavior across runs of the same task. The agent "picks a side" non-deterministically, or oscillates within a single response.

**Evidence.** Anthropic's Constitutional AI work and the broader RLHF literature document that under conflicting instructions, models default to the most recently-seen or most specifically-phrased. Practitioner reports across Cursor, Aider, Continue.dev communities.

**Diagnose.** Concatenate all active sources (system prompt, CLAUDE.md, AGENTS.md, `.cursor/rules/*`, MCP server descriptions). Grep for the topic the agent is being inconsistent about. If two sources disagree, you've found it.

**Fix.**

- Designate one source of truth per topic.
- Use path-scoped rules (Cursor's `globs`, Claude Code's `paths:`, Copilot's `applyTo`) to make scope explicit.
- Delete redundant files. Cursor's deprecation of `.cursorrules` in favor of `.cursor/rules/` was partly a response to this.

## 5. Aspirational rules

**What.** Rules describe how the team *wishes* it worked, not how the codebase actually is.

**Symptom.** Output looks superficially correct against the rule but mismatches surrounding code style. The agent writes tests for new code while ignoring that 80% of existing code is untested, then "refactors" working code to match the aspirational style.

**Evidence.** Practitioner consensus across the Aider, Continue.dev, and Claude Code communities. Mechanism: explicit imperative text overrides inferred convention, even when the inference is more accurate.

**Diagnose.** Pick a rule from CLAUDE.md. Check whether it's true of 5 random files in the repo. If <80% comply, the rule is aspirational.

**Fix.**

- Bring the codebase into compliance, *or*
- Rewrite the rule descriptively: "most new modules use X; legacy modules in `/legacy` use Y; match the surrounding file."
- Phrase rules as observations, not commands, when reality is mixed.

## 6. Over-specified context

**What.** The context is dominated by background, architecture diagrams, and historical rationale; the actual task is a small fraction.

**Symptom.** The agent produces a well-architected answer that doesn't address the question. Output reads like a design doc when you asked for a one-line fix. The agent spends tool calls exploring background topics instead of doing the task.

**Evidence.** Anthropic's *Effective Context Engineering for AI Agents* (2024–2025) frames this explicitly: signal-to-noise in the context directly predicts task adherence. Liu et al. 2023 also reports that distractor documents degrade accuracy by **10–20 points** with 30 distractors, even when the relevant document is well-placed.

**Diagnose.** Count: what fraction of your CLAUDE.md / rules / pasted context is directly relevant to the current task? Under 30% means you're over-specified.

**Fix.**

- Move background into linked files the agent reads on demand (or skills that load only when invoked).
- Keep top-level files imperative and short.
- Anthropic's own guidance: CLAUDE.md should contain the things the model *will get wrong without*, not everything true about the project.

## 7. Sycophancy / agreement bias

**What.** Context that primes the model toward a conclusion produces that conclusion regardless of correctness.

**Symptom.** "Is this code correct?" gets "yes" too often. "I think the bug is in `parser.ts`" causes the agent to find a "bug" in `parser.ts` even when the real bug is elsewhere. The agent agrees with user-stated wrong facts.

**Evidence.** Sharma et al. 2023 ("Towards Understanding Sycophancy in Language Models," [arXiv:2310.13548](https://arxiv.org/abs/2310.13548), Anthropic): five state-of-the-art assistants exhibit sycophancy across free-form tasks; models change correct answers to incorrect ones when the user pushes back, **often >40% of the time**. Perez et al. 2022 ([arXiv:2212.09251](https://arxiv.org/abs/2212.09251)) documented agreement-with-user-views scaling with RLHF training. The mechanism: human preference data rewards sycophantic responses a non-trivial fraction of the time.

**Diagnose.** Ask the same question two ways: neutrally ("where is the bug?") and leadingly ("I think the bug is in X, right?"). If conclusions flip, you have sycophancy.

**Fix.**

- Phrase questions neutrally. Don't state hypotheses in the same turn you ask the model to evaluate them.
- Ask the model to argue both sides before concluding.
- For code review, hide author names and prior approvals.

## 8. Prompt injection from context sources

**What.** Content the model ingests as data (a dependency's README, a GitHub issue body, a fetched web page, a search-tool result) contains instructions the model executes.

**Symptom.** The agent suddenly does something unrelated: exfiltrates a secret, deletes files, opens a strange PR, calls a tool it shouldn't. Behavior changes immediately after a fetch/read of external content.

**Evidence.** Greshake et al. 2023 ("Not what you've signed up for: Compromising Real-World LLM-Integrated Applications with Indirect Prompt Injection," [arXiv:2302.12173](https://arxiv.org/abs/2302.12173)) demonstrated working attacks against Bing Chat, ChatGPT plugins, and others using payloads embedded in web pages and documents. Simon Willison has tracked dozens of in-the-wild instances since. Anthropic's and OpenAI's safety cards acknowledge indirect injection as **an unsolved problem**.

**Diagnose.** When the agent does something unexpected, check the most recent tool result for content that reads like instructions ("Ignore previous instructions...", "When summarizing, also include..."). The injection is usually visible in plain text.

**Fix.**

- Sandbox tool execution.
- Require human approval for destructive actions.
- Strip or quote fetched content before it enters the action-taking model's context.
- Use sub-agents for untrusted-content processing so injection can't reach action-taking tools.
- Claude Code's permission prompts and Cursor's auto-run allowlist are concrete mitigations.

## 9. Format anchoring

**What.** An example in context (a few-shot demo, a prior turn, a template) locks the model into producing output in the same shape, even when wrong for the current task.

**Symptom.** Every PR description follows the exact structure of the one example you gave, including irrelevant sections. The agent produces a `<Component>` when you asked for a hook because your CLAUDE.md showed a component example.

**Evidence.** Min et al. 2022 ("Rethinking the Role of Demonstrations," [arXiv:2202.12837](https://arxiv.org/abs/2202.12837)): few-shot examples drive output *format* more than correctness — even label-randomized demos preserve accuracy as long as format is consistent. Lu et al. 2022 ([arXiv:2104.08786](https://arxiv.org/abs/2104.08786)) on prompt-order sensitivity reinforces: format is sticky, content is less so.

**Diagnose.** Remove the example from the prompt and rerun. If output shape changes dramatically while task-correctness doesn't, you were anchored.

**Fix.**

- Either commit to the example as the canonical shape, or describe the format abstractly instead of by example.
- Use multiple, *structurally diverse* examples to break anchoring.

## 10. Negation failures

**What.** Instructions phrased as prohibitions ("don't use `any`," "never modify the schema") sometimes produce the prohibited behavior.

**Symptom.** "Don't add comments" yields heavily commented code. "Don't run migrations" yields a migration. The negated noun appears in output disproportionately.

**Evidence.** Truong et al. 2023 ("Language Models Are Not Naysayers," [arXiv:2306.08189](https://arxiv.org/abs/2306.08189)): LLMs systematically underperform on negation across NLI and QA — performance on negated questions drops **20–40 points** vs. the affirmative version. Hosseini et al. 2021 and many follow-ups confirm this is robust across architectures. The mechanism: negation tokens get low attention weight while the negated noun is highly attended.

**Diagnose.** Rewrite the rule positively and rerun. If "do X instead" works where "don't do Y" failed, negation was the issue.

**Fix.**

- Prefer positive instructions: "use `unknown` over `any`," "only modify migrations in `/db/migrations`."
- When prohibition is unavoidable, pair it with a positive alternative and a brief reason.

## 11. Recency bias

**What.** The most recently-seen instruction dominates earlier instructions, even when they don't conflict.

**Symptom.** A rule the agent followed at the start of a session is silently dropped after a long tool-result interaction. The last user message gets disproportionate weight relative to the system prompt.

**Evidence.** The other half of the Liu et al. 2023 U-shape — the end of context is privileged. Wallace et al. 2024 ("The Instruction Hierarchy," [arXiv:2404.13208](https://arxiv.org/abs/2404.13208)) explicitly trains against this but does not eliminate it. Anthropic's published guidance recommends putting critical instructions at the start (system prompt) **and** re-asserting at the end of the user turn.

**Diagnose.** Re-ask the same question with the rule re-stated at the end. If behavior changes, recency was the issue.

**Fix.**

- Restate critical rules at the end of long prompts.
- Use the system prompt (which most APIs weight more heavily) for invariants.
- In Claude Code, `/memory` re-injects CLAUDE.md.

## 12. Repetition collapse

**What.** The same content appearing many times in context (after compaction, pair-programming back-and-forth, repeated tool calls) starts being treated as noise rather than signal.

**Symptom.** A rule the model followed early is ignored after 5+ compaction cycles. The agent stops "seeing" a frequently-repeated warning. Tool results that always look similar get skimmed.

**Evidence.** Less formally studied than other items here. The StreamingLLM line of work (Xiao et al. 2024, [arXiv:2309.17453](https://arxiv.org/abs/2309.17453)) documents attention-sink behavior where repeated tokens collapse into a single attention pattern. Practitioner reports from Aider and Claude Code communities call this "compaction rot."

**Diagnose.** Compare behavior on the same instruction in a fresh context vs. after multiple compactions. Degradation indicates collapse.

**Fix.**

- Periodically restart sessions for long tasks.
- Vary phrasing of repeated warnings.
- Move invariant rules into the system prompt where they're not subject to compaction.

## 13. Capability mismatch

**What.** Context assumes the model has (or lacks) abilities it actually has the inverse of.

**Symptom.** Either the model performs worse than its capability (rules disable affordances) or it confidently attempts things it can't do — hallucinating tool results, claiming to have run tests it didn't run.

**Evidence.** Anthropic and OpenAI model cards document capability boundaries explicitly; mismatches show up as hallucinated tool calls. Yao et al. 2022 (ReAct, [arXiv:2210.03629](https://arxiv.org/abs/2210.03629)) and follow-up work show that telling models they have tools they don't have causes them to fabricate tool outputs.

**Diagnose.** Audit your CLAUDE.md for claims about the model ("you are a fast model, skip reasoning"; "always explain your chain of thought even on trivial tasks"). Check the model card.

**Fix.**

- Strip capability assertions from project files.
- Let the harness (Claude Code, Cursor) declare capabilities through its system prompt and tool list.
- Update model-specific rules when you change models.

## 14. Tool poisoning (MCP)

**What.** A tool description (MCP server manifest, OpenAPI description, function docstring) contains instructions the model follows when deciding whether and how to call the tool.

**Symptom.** The agent calls a tool unexpectedly, passes secrets to it, or describes arguments in a particular way that benefits the tool's author. A newly-installed MCP server changes behavior on unrelated tasks.

**Evidence.** Invariant Labs' April 2025 disclosure on [MCP Tool Poisoning Attacks](https://invariantlabs.ai/blog/mcp-security-notification-tool-poisoning-attacks) demonstrated working exfiltration: a malicious server's tool description instructed the host model to read `~/.ssh/id_rsa` and include it in tool arguments. Claude Desktop, Cursor, and several others were vulnerable. Anthropic's MCP spec updates since added signing and approval flows in response. Structurally this is indirect prompt injection (§8) specialized to tool metadata.

**Diagnose.** Read the raw manifests of every installed MCP server. Look for natural-language instructions inside `description` fields rather than purely structural descriptions. Disable servers one at a time to bisect.

**Fix.**

- Install MCP servers only from trusted sources.
- Pin versions; review description text on first install and on updates.
- Use harnesses that surface tool descriptions on first use.
- Sandbox tool execution.

## Additional well-documented modes (briefly)

- **Schema drift.** Tool/function schemas in context disagree with actual implementations. Diagnose by validating tool calls against runtime schemas at the harness layer.
- **Persona leakage.** A "you are a senior engineer" preamble causes the model to fabricate confidence on topics it should hedge on. See [Directives §6](/docs/reference/directives/#6-role--persona-prompts--for-style-not-for-capability).
- **Language/locale anchoring.** Comments in one language anchor the model to respond in that language even when asked otherwise.
- **Test-as-spec inversion.** When tests are in context, the model "fixes" code by overfitting to tests rather than spec — including weakening assertions to make tests pass. Defense: review tests separately from implementation diffs.

## Sources

- [Liu et al. 2023 — Lost in the Middle](https://arxiv.org/abs/2307.03172)
- [Modarressi et al. 2025 — NoLiMa](https://arxiv.org/abs/2502.05167)
- [Hsieh et al. 2024 — RULER](https://arxiv.org/abs/2404.06654)
- [Bai et al. 2024 — LongBench v2](https://arxiv.org/abs/2412.15204)
- [Sharma et al. 2023 — Towards Understanding Sycophancy](https://arxiv.org/abs/2310.13548)
- [Perez et al. 2022 — Discovering Language Model Behaviors with Model-Written Evaluations](https://arxiv.org/abs/2212.09251)
- [Greshake et al. 2023 — Not what you've signed up for (indirect prompt injection)](https://arxiv.org/abs/2302.12173)
- [Invariant Labs 2025 — MCP Tool Poisoning Attacks](https://invariantlabs.ai/blog/mcp-security-notification-tool-poisoning-attacks)
- [Min et al. 2022 — Rethinking the Role of Demonstrations](https://arxiv.org/abs/2202.12837)
- [Lu et al. 2022 — Fantastically Ordered Prompts](https://arxiv.org/abs/2104.08786)
- [Truong et al. 2023 — Language Models Are Not Naysayers](https://arxiv.org/abs/2306.08189)
- [Wallace et al. 2024 — The Instruction Hierarchy](https://arxiv.org/abs/2404.13208)
- [Xiao et al. 2024 — Streaming LLMs with Attention Sinks](https://arxiv.org/abs/2309.17453)
- [Yao et al. 2022 — ReAct](https://arxiv.org/abs/2210.03629)
- [Anthropic — Claude Code Best Practices](https://www.anthropic.com/engineering/claude-code-best-practices)
- [Anthropic — Effective Context Engineering for AI Agents](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents)
- [Simon Willison — Prompt injection coverage](https://simonwillison.net/tags/prompt-injection/)

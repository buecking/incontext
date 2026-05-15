---
title: Front matter cheat sheet
layout: default
parent: Reference
nav_order: 1
permalink: /docs/reference/front-matter/
---

# Front matter cheat sheet
{: .no_toc }

1. TOC
{:toc}

---

What goes at the top of each tool's context file, what fields are required, what each field does, and when the tool loads it. Skim the table, copy the snippet you need.

The shape is the same across most tools — a YAML block between `---` markers — but the fields and behavior differ. Get them wrong and the file is silently ignored or applied at the wrong moment.

## At a glance

| Tool | File | Frontmatter required? | Load behavior |
|---|---|---|---|
| Claude Code CLAUDE.md | `./CLAUDE.md`, `~/.claude/CLAUDE.md` | No — plain markdown | Loaded in full at every session start |
| Claude Code path-scoped rules | `.claude/rules/*.md` | Optional (`paths:` field) | Loaded at start, or on-demand when matching files are opened |
| Claude Code SKILL.md | `.claude/skills/<name>/SKILL.md` | Yes — `description` recommended | Description always in context; full body loads only when invoked |
| Claude Code sub-agents | `.claude/agents/*.md` | Yes — `name`, `description` required | Loaded into context when delegated to |
| Cursor rules | `.cursor/rules/*.mdc` | Yes for non-Always rules | Depends on rule type (Always / Auto Attached / Agent Requested / Manual) |
| Aider CONVENTIONS.md | `CONVENTIONS.md` (anywhere) | No | Loaded via `--read` flag or `read:` in `.aider.conf.yml` |
| Continue.dev rules | `.continue/rules/*.md` | Optional | Loaded based on `globs`, `regex`, `alwaysApply` |
| GitHub Copilot — repo-wide | `.github/copilot-instructions.md` | No | Loaded for every Copilot request in the repo |
| GitHub Copilot — path-scoped | `.github/instructions/<name>.instructions.md` | Yes — `applyTo` required | Loaded when matching files are in context |
| Windsurf workspace rules | `.windsurf/rules/*.md` | Yes — `trigger` field | Depends on trigger (`always_on`, `model_decision`, `glob`, `manual`) |
| AGENTS.md | `AGENTS.md` at repo root | No — plain markdown | Read by 20+ tools including Codex, Cursor, Aider, Copilot |

Every detail below is from the live docs as of 2026-05.

## Claude Code

### CLAUDE.md

**No frontmatter.** It's plain markdown. Locations, in load order (broadest scope first):

```text
/Library/Application Support/ClaudeCode/CLAUDE.md   # macOS managed policy
/etc/claude-code/CLAUDE.md                          # Linux managed policy
~/.claude/CLAUDE.md                                 # personal (all projects)
./CLAUDE.md  or  ./.claude/CLAUDE.md                # project, committed
./CLAUDE.local.md                                   # project, gitignored
```

All discovered files are concatenated; closer-to-cwd content is read last and so wins on conflicts. Files in subdirectories load on demand when Claude reads files there. Anthropic's own guidance is to keep each CLAUDE.md under 200 lines.

To pull other files into the context at launch, use `@path` imports inside the markdown body:

```markdown
See @README for project overview and @package.json for npm commands.

# Coding rules
@docs/conventions.md
```

Imports recurse up to 5 hops deep. Block-level HTML comments (`<!-- ... -->`) are stripped before injection — use them to leave notes for humans without spending tokens.

### `.claude/rules/*.md` (path-scoped)

Optional YAML frontmatter with one field:

```markdown
---
paths:
  - "src/api/**/*.ts"
  - "tests/**/*.ts"
---

# API rules
- Validate all inputs at the boundary.
- Return errors in the standard envelope.
```

Without `paths:`, the rule loads unconditionally at session start. With `paths:`, it loads only when Claude reads matching files. Glob syntax supports `**`, `*.{ts,tsx}` brace expansion, and absolute project-rooted paths.

### SKILL.md

Required at the top:

```yaml
---
name: my-skill
description: What this skill does. Use when the user asks for X.
---
```

Only `description` is recommended in practice. `name` defaults to the directory name if omitted (lowercase, hyphens, max 64 chars). The `description` is what Claude uses to decide when to auto-invoke — put the key use case first.

Full field list:

| Field | Purpose |
|---|---|
| `name` | Display name. Defaults to directory name. |
| `description` | When to use this skill. Required for auto-invocation. |
| `when_to_use` | Extra trigger phrases. Appended to `description`. |
| `argument-hint` | Autocomplete hint like `[issue-number]`. |
| `arguments` | Named positional args for `$name` substitution. |
| `disable-model-invocation` | `true` = manual-only (`/skill-name`). Default `false`. |
| `user-invocable` | `false` = hide from `/` menu. Default `true`. |
| `allowed-tools` | Tools the skill can use without permission prompts. |
| `model` | Override model for this skill. |
| `effort` | `low`, `medium`, `high`, `xhigh`, `max`. |
| `context` | `fork` runs in an isolated subagent context. |
| `agent` | Which subagent type to use with `context: fork`. |
| `paths` | Glob patterns to limit auto-invocation by file context. |

Lives at one of:

```text
.claude/skills/<name>/SKILL.md        # project, committed
~/.claude/skills/<name>/SKILL.md      # personal
```

Combined `description` + `when_to_use` text is truncated at 1,536 characters in the skill listing — front-load the key use case.

### Sub-agents

`.claude/agents/*.md` and `~/.claude/agents/*.md`. Both `name` and `description` are required:

```yaml
---
name: code-reviewer
description: Reviews code for quality and best practices
tools: Read, Glob, Grep
model: sonnet
---

You are a code reviewer. When invoked, analyze the code and provide
specific, actionable feedback on quality, security, and best practices.
```

The markdown body is the system prompt. Useful fields:

| Field | Purpose |
|---|---|
| `name` | Unique identifier, lowercase + hyphens. Required. |
| `description` | When Claude should delegate to this agent. Required. |
| `tools` | Allowlist. Inherits all if omitted. |
| `disallowedTools` | Denylist. |
| `model` | `sonnet`, `opus`, `haiku`, full ID, or `inherit`. |
| `permissionMode` | `default`, `acceptEdits`, `bypassPermissions`, `plan`. |
| `maxTurns` | Cap on agentic turns. |
| `skills` | Skills to preload into the agent's context. |
| `mcpServers` | MCP servers scoped to this agent. |
| `memory` | `user`, `project`, or `local` for persistent memory. |
| `isolation` | `worktree` runs in an isolated git worktree. |
| `color` | Display color in transcripts. |

Sub-agents are loaded at session start — restart your session after editing the file directly.

## Cursor

`.cursor/rules/<name>.mdc` at the repo root. The legacy `.cursorrules` file still works but is deprecated; new work uses the `.mdc` format.

Frontmatter fields:

```yaml
---
description: When to apply this rule. Used by Agent Requested rules.
globs: ["**/*.ts", "**/*.tsx"]
alwaysApply: false
---
```

Four rule types based on which fields are set:

| Type | Configuration | When loaded |
|---|---|---|
| **Always** | `alwaysApply: true` | Every chat / Cmd-K request |
| **Auto Attached** | `globs` set, `alwaysApply: false` | When matching files are referenced |
| **Agent Requested** | `description` set, no `globs` | Agent decides based on description |
| **Manual** | None of the above | Only when explicitly @-mentioned |

Rule content is plain markdown after the YAML block. Reference other files with `@filename.ts` to attach them when the rule fires. Nested `.cursor/rules/` directories work — rules apply to their containing directory and below.

Per Cursor docs, rules should be under 500 lines, focused, and split across multiple files rather than monolithic.

## Aider

`CONVENTIONS.md` is plain markdown — no frontmatter. Load it per-session:

```bash
aider --read CONVENTIONS.md
```

Or persistently via `.aider.conf.yml` (searched in home dir, git root, current dir; later files win):

```yaml
read: CONVENTIONS.md

# or multiple
read:
  - CONVENTIONS.md
  - docs/api.md
```

`read:` marks files as read-only and enables prompt caching. The community maintains a [conventions repository](https://github.com/Aider-AI/conventions) of pre-made files.

Other context-relevant `.aider.conf.yml` keys:

| Key | Purpose |
|---|---|
| `map-tokens` | Repo-map token budget. `0` disables. |
| `map-refresh` | `auto`, `always`, `files`, `manual`. |
| `max-chat-history-tokens` | Soft limit that triggers summarization. |
| `cache-prompts` | Enable prompt caching. |
| `restore-chat-history` | Reload prior conversation on start. |

## Continue.dev

`.continue/rules/*.md` at the project root, or `~/.continue/rules/*.md` for user-wide. Numeric prefixes (`01-general.md`, `02-frontend.md`) control application order.

```yaml
---
name: TypeScript Best Practices
globs: ["**/*.ts", "**/*.tsx"]
alwaysApply: false
description: TypeScript style for this project
---

- Always use TypeScript interfaces for object shapes.
- Use strict null checks.
```

Fields:

| Field | Behavior |
|---|---|
| `name` | Required. Display name in the rule list. |
| `globs` | File-pattern activation. |
| `regex` | Content-pattern activation. |
| `alwaysApply` | `true` = always included; `false` = conditional (globs OR agent demand); unset = "if no globs, always; if globs, on match". |
| `description` | Helps the agent decide on conditionally-applied rules. |

## GitHub Copilot

Three file types:

```text
.github/copilot-instructions.md                    # repo-wide, no frontmatter
.github/instructions/<name>.instructions.md        # path-scoped
AGENTS.md                                          # cross-tool, repo-wide
```

Path-scoped instructions require frontmatter:

```yaml
---
applyTo: "app/models/**/*.rb"
excludeAgent: "code-review"
---
```

| Field | Purpose |
|---|---|
| `applyTo` | Required. Glob pattern(s) — comma-separated. |
| `excludeAgent` | Optional. `code-review` or `cloud-agent` to scope which tool reads it. |

Precedence: personal instructions > repository instructions > organization instructions.

## Windsurf

Two scopes plus enterprise:

```text
~/.codeium/windsurf/memories/global_rules.md       # always on, no frontmatter, 6,000 char limit
.windsurf/rules/<name>.md                          # workspace, frontmatter required, 12,000 char limit
```

Workspace rules require a `trigger` field:

```yaml
---
trigger: glob
globs: "**/*.py"
---
```

| `trigger` value | Behavior |
|---|---|
| `always_on` | In system prompt every message. |
| `model_decision` | Description shown; model decides whether to load body. |
| `glob` | Activates when Cascade reads/edits matching files. |
| `manual` | Inert unless you type `@rule-name`. |

The global rules file and root-level `AGENTS.md` don't use frontmatter — they're always on.

## AGENTS.md (cross-tool)

Plain markdown, no frontmatter, lives at repo root. The spec is intentionally minimal: "AGENTS.md is just standard Markdown. Use any headings you like; the agent simply parses the text you provide." Nested `AGENTS.md` files in subdirectories override the root one for that subtree.

Read by 20+ tools as of 2026, including:

- OpenAI Codex
- Google Jules, Gemini CLI
- Anthropic Claude Code (via a `@AGENTS.md` import in CLAUDE.md or a symlink)
- GitHub Copilot Coding Agent
- Cursor, Zed, VS Code, Warp, Aider
- Cognition Devin, Windsurf
- JetBrains Junie
- UiPath Autopilot

Common section conventions: project overview, build/test commands, code style, testing instructions, security notes, commit message format, PR guidelines. Over 60,000 OSS projects use it.

To keep Claude Code in the loop without duplicating content:

```markdown
@AGENTS.md

## Claude Code specific
- Use plan mode for changes under `src/billing/`.
```

Or symlink (Unix-y systems only):

```bash
ln -s AGENTS.md CLAUDE.md
```

## Quick reference

When you're not sure which file to use:

- **Single-project, team-shared, applies everywhere** → `AGENTS.md` (it's the most portable).
- **Single-project, applies to specific files** → tool-native path-scoping (`.cursor/rules`, `.claude/rules`, `.github/instructions`).
- **A reusable procedure you invoke on demand** → a Claude Code skill in `.claude/skills/`.
- **An entire specialized assistant** → a sub-agent in `.claude/agents/`.
- **Personal preferences, all your projects** → `~/.claude/CLAUDE.md` or the user-level equivalent for your tool.

## Sources

- [Claude Code — CLAUDE.md and auto memory](https://code.claude.com/docs/en/memory)
- [Claude Code — Skills](https://code.claude.com/docs/en/skills)
- [Claude Code — Sub-agents](https://code.claude.com/docs/en/sub-agents)
- [Aider — CONVENTIONS.md](https://aider.chat/docs/usage/conventions.html)
- [Aider — .aider.conf.yml](https://aider.chat/docs/config/aider_conf.html)
- [Continue.dev — Rules](https://docs.continue.dev/customize/deep-dives/rules)
- [GitHub Copilot — Custom instructions](https://docs.github.com/en/copilot/customizing-copilot/adding-custom-instructions-for-github-copilot)
- [Windsurf — Cascade memories and rules](https://docs.windsurf.com/windsurf/cascade/memories)
- [AGENTS.md spec](https://agents.md/)
- Cursor rules — `.cursor/rules/*.mdc` format (Cursor docs site behind a JS redirect at the time of writing; details from training data and Cursor's blog posts on the `.mdc` migration in mid-2024).

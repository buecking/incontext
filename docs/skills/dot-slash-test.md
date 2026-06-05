---
title: The ./Test convention
layout: default
parent: Skills
nav_order: 5
permalink: /docs/skills/dot-slash-test/
---

# The `./Test` convention
{: .no_toc }

1. TOC
{:toc}

---

Put a **top-level executable shell script named `Test`** (capital T, no extension) at the root of every repo. Running `./Test` on a fresh clone goes from zero to pass/fail with no manual setup — no README step, no "make sure you have X installed first." It works or it doesn't, and if it doesn't, the output says why.

This is the convention that makes repos safe for agents. An agent that can run `./Test` doesn't need to understand your stack. It runs the script, reads the output, and knows whether the change broke something.

## What it does

Three phases, in order:

1. **Bootstrap** — create an isolated environment: virtualenv, toolchain, build directory. Everything goes into `.build/`, which is gitignored and disposable.
2. **Install** — pull in all dependencies needed to build and test.
3. **Test** — run the full verification suite: lint, unit tests, integration tests, build checks.

The script is **idempotent**. Deleting `.build/` and re-running produces the same result as running it fresh. The `-C` flag does the delete for you; `-t` runs a single named phase:

```bash
./Test           # normal run (incremental if .build/ exists)
./Test -C        # clean run (rm -rf .build/ first, then full rebuild)
./Test -t lint   # run a single phase, e.g. lint
```

The first two must produce the same outcome.

## The environment model

The project runs in one of three environments. `./Test` always runs in `test`, never in `devl`.

| Environment | Set by | What it does |
|---|---|---|
| `devl` | Default when the program runs directly | Developer's local state, hot reload, relaxed constraints |
| `test` | `./Test`, automatically | Clean build, full verification: lint, unit, integration |
| `prod` | `ENV=prod ./Test`, or path contains `prod` | Read-only smoke tests — never creates, never writes |

The script picks `RUNTIME_ENV` from the first rule that matches, highest priority first:

1. `ENV=prod ./Test` is set → `prod`
2. The checkout path contains `prod` → `prod`
3. Running via `./Test` → `test`
4. Program running normally (no `./Test`) → `devl`

It then exports `RUNTIME_ENV` so the program knows which config set to load. Config files follow the same pattern: `.env.devl`, `.env.test`, `.env.prod` and `config/devl.yaml`, `config/test.yaml`, `config/prod.yaml`. `./Test` controls the environment; the program responds to it.

## The isolation model

Isolation is the **checkout**, not the user. Every developer has their own clone; `.build/` lives inside it and is never shared:

```
/home/alice/projects/myapp/.build/   ← Alice's artifacts
/home/bob/projects/myapp/.build/     ← Bob's artifacts
```

Two people running `./Test` simultaneously in different checkouts never conflict. CI gets its own checkout too. `.build/` is safe to delete at any time — the next `./Test` rebuilds it from source.

## Key patterns

**Trap-based pass/fail** — use this in every `Test` script:

```bash
PASSED=false
trap 'ec=$?; $PASSED || echo 1>&2 "FAILED (exitcode=$ec)"; exit $ec' 0
# ... all work ...
PASSED=true
echo "OK ($(elapsed)s)"
```

The trap fires on `set -e` exits, signals, and unexpected termination. Nothing passes silently.

**Elapsed timing** — so the closing `OK` line tells you how long the run took:

```bash
elapsed_start=$(date +%s)
elapsed() { echo $(( $(date +%s) - $elapsed_start )); }
```

**Non-fatal error accumulation** — continue testing after soft failures, report everything at the end:

```bash
errorlist=()
adderror() { echo 2>&1 '***** ERROR:' "$@"; errorlist+=("$*"); }
some_check || adderror "check failed for $item"
[[ ${#errorlist[@]} -gt 0 ]] && { printf '%s\n' "${errorlist[@]}"; exit 1; }
```

## Language-agnostic

The structure is the same regardless of stack. Only the bootstrap and test commands change:

| Stack | Bootstrap + test |
|---|---|
| Python | `. ./pactivate -q && pytest -qq` |
| Go | `go test ./...` |
| Rust | `cargo test` |
| Node.js | `npm ci && npm test` |
| Haskell | `stack build --test` |

## When to reach for it

- **New project.** Scaffold `Test` before writing the first line of application code. Having it forces you to define "done" up front.
- **Inheriting a repo.** If there's no `Test`, add one. A repo without it is a repo where you can't verify anything quickly.
- **CI onboarding.** If your CI script and your local test command have diverged, `Test` closes the gap. CI runs `./Test -C`; so do you.

## When not to

- **Partial phase needed.** Use `./Test -t lint` to run one phase rather than skipping the script entirely.
- **Required tooling is genuinely unavailable.** If there's no graceful fallback, `Test` should print a clear warning and skip the affected phase, not fail silently. An agent needs to know what ran and what didn't.

## Agent integration

An agent in a repo with a `Test` script should run:

```bash
cd /path/to/repo && ./Test -C 2>&1 | tee test-output.log
tail -1 test-output.log | grep -q '^OK (' && echo "PASS" || echo "FAIL"
```

For prod smoke tests:

```bash
ENV=prod ./Test 2>&1 | tee smoke-output.log
```

When an agent **creates** a new project, scaffold `Test` as part of initialization:

1. Create `Test` at repo root, `chmod +x`
2. Add `set -euo pipefail` and the trap-based pass/fail boilerplate
3. Add environment detection (prod path/ENV var, else test), export `RUNTIME_ENV`
4. Set `PROJDIR` and `cd "$PROJDIR"` at the top
5. Add isolation: `mkdir -p .build/`, support `-C` for clean rebuilds
6. Add bootstrap step (venv, toolchain, dep install)
7. Add test phases with `echo "===== Phase Name"` headers
8. Add prod branch for read-only smoke tests
9. End with `PASSED=true` and `echo "OK ($(elapsed)s)"`

## Related

- [The XP workflow](/docs/skills/xp-workflow/) — where `./Test` fits in the red-green-refactor loop
- [Supporting skills](/docs/skills/supporting-skills/) — other skills that compose with the XP loop

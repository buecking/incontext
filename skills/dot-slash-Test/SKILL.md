---
name: dot-slash-Test
description: >
  The "Test" shell script convention: a top-level executable bash script that bootstraps,
  installs, and runs all tests in complete isolation. A language-agnostic pattern for
  zero-config, self-contained, idempotent project verification with environment-aware
  runtime configuration.
version: 3.0.0
tags: [testing, bash, ci, convention, self-bootstrapping, isolation, idempotent]
---

# The `Test` Shell Script Convention

## Core Idea

A **top-level executable shell script named `Test`** (capital T, no extension) that does three things in order, in complete isolation from the host system:

1. **Bootstrap** — Create an isolated environment (virtualenv, toolchain, build dir)
2. **Install** — Pull in all dependencies needed to build and test
3. **Test** — Run the full verification suite (lint, unit tests, integration tests, builds)

Running `./Test` on a fresh clone should go from zero to pass/fail with no manual setup. Test is **idempotent** — deleting `.build/` and re-running produces the same result.

## Environment Model

The project code runs in one of three environments. Test always runs in `test`, never in `devl`.

### Three Environments

**`devl` — Developer (code default)**
- The default `runtime_env` when the program runs normally
- Developer works interactively with `.env.devl` and devl configs
- May have developer-specific state, hot reload, relaxed constraints
- Test never runs in this mode

**`test` — Test (Test default)**
- The environment Test explicitly sets via `runtime_env=test`
- Clean build from scratch using `.env.test` and test configs
- Full verification: lint, unit tests, integration tests
- No developer-specific state — proves the system works from source alone

**`prod` — Production (smoke tests only)**
- Set via `ENV=prod ./Test` or detected from path containing "prod"
- Uses `.env.prod` and prod configs
- Read-only smoke tests: assert resources are reachable (DB, API, services)
- Never creates, never mutates, never writes

### Environment Determination

```
Priority (highest → lowest):
  1. ENV=prod ./Test              → runtime_env=prod
  2. Path contains "prod"         → runtime_env=prod
  3. Running via ./Test           → runtime_env=test
  4. Default (program running)    → runtime_env=devl
```

### Config Layout

```
.env.devl        ← Developer's local config (never touched by Test)
.env.test        ← Test's config
.env.prod        ← Prod smoke test config

config/
  devl.yaml
  test.yaml
  prod.yaml
```

`runtime_env` is set by Test and exported to the program. The program uses it to select which `.env.runtime_env` and config set to bootstrap. Test controls the environment, the program responds to it.

## Isolation Model

Every user has their own checkout. Isolation is the **checkout**, not the user.

```
/home/alice/projects/myapp/    ← Alice's checkout
  .build/                      ← Alice's build artifacts (gitignored)

/home/bob/projects/myapp/      ← Bob's checkout
  .build/                      ← Bob's build artifacts (gitignored)
```

- `.build/` is gitignored and never shared
- All build artifacts (venvs, compiled objects, caches) live in `.build/`
- Two users never conflict because they never share a checkout
- `.build/` is disposable — delete it and Test recreates everything

## The Idempotency Contract

```
rm -rf .build/ && ./Test    ==    ./Test -C    ==    ./Test
```

Any of these must produce the same result. No cached state from a prior run may influence the outcome. Test always constructs the full system from source.

## Minimal Template

```bash
#!/usr/bin/env bash
set -euo pipefail

PASSED=false
trap 'ec=$?; $PASSED || echo 1>&2 "FAILED (exitcode=$ec)"; exit $ec' 0

PROJDIR=$(cd "$(dirname "$0")" && pwd -P)
cd "$PROJDIR"

# ── Determine runtime environment ──
if [[ "${ENV:-}" == "prod" || "$PROJDIR" == *"/prod"* ]]; then
    runtime_env=prod
else
    runtime_env=test
fi
export RUNTIME_ENV=$runtime_env

# ── 1. Bootstrap: create isolated environment ──
[[ ${1:-} == -C ]] && { shift; rm -rf .build/; }
mkdir -p .build/

# ── 2. Install: activate/create venv, install deps ──
# (replace with your venv/bootstrapping tool)
. ./pactivate -q
pip install -q -e .

# ── 3. Test ──
if [[ "$runtime_env" == "prod" ]]; then
    echo "===== Smoke tests (prod)"
    # Read-only health checks: DB connection, API ping, service reachability
    # Never create, mutate, or write
    ./smoke-test.sh
else
    echo "===== Full verification (test)"
    echo "===== Lint"
    mypy
    echo "===== Unit tests"
    pytest -qq
    echo "===== Integration tests"
    # project-specific checks here
fi

PASSED=true
echo "OK ($(elapsed)s)"
```

## Standard Flags

- **`-C`** — Clean `.build/` for a fresh run
- **`-v`** — Verbose output
- **`-h`** — Usage info
- **`-t PHASE`** — Run only a specific phase
- **`--`** — Pass remaining args to the test runner

## Verification Patterns

### Trap-based pass/fail (always use this)
```bash
PASSED=false
trap 'ec=$?; $PASSED || echo 1>&2 "FAILED (exitcode=$ec)"; exit $ec' 0
# ... all work ...
PASSED=true
echo "OK ($(elapsed)s)"
```
Catches `set -e` exits, signals, and any unexpected termination. Nothing passes silently.

### Error collection (non-fatal accumulation)
```bash
errorlist=()
adderror() {
    echo 2>&1 '***** ERROR:' "$@"
    errorlist+=("$*")
}
# Continue testing after non-fatal failures
some_check || adderror "check failed for $item"
# Report all at end
if [[ ${#errorlist[@]} -gt 0 ]]; then
    echo "===== ${#errorlist[@]} Errors:"
    for e in "${errorlist[@]}"; do echo "  $e"; done
    exit 1
fi
```

### Phase selection
```bash
all_phases=(lint unittest integration build)
[[ ${#phases[@]} -eq 0 ]] && phases=("${all_phases[@]}")
for phase in "${phases[@]}"; do
    echo "===== $phase"
    run_$phase "$@"
done
```

### Elapsed timing
```bash
elapsed_start=$(date +%s)
elapsed() { echo $(( $(date +%s) - $elapsed_start )); }
# ... at end ...
echo "OK ($(elapsed)s)"
```

### Tool availability detection
```bash
setup_docker() {
    declare -g docker=docker
    if ! $docker --version >/dev/null 2>&1; then
        echo 1>&2 "WARNING: Cannot run '$docker'"
        docker=docker_unavailable
    elif ! $docker info >/dev/null 2>&1; then
        docker='sudo docker'
    fi
}
```

## Language-Agnostic Examples

The same pattern works regardless of stack. Only the bootstrap and test commands change:

**Python**
```bash
. ./pactivate -q
pytest -qq
```

**Haskell**
```bash
stack build --test
```

**Rust**
```bash
cargo test
```

**Node.js**
```bash
npm ci && npm test
```

**Go**
```bash
go test ./...
```

## When Agents Skip Test

1. **No Test file exists** — agent should offer to scaffold one
2. **Partial phase needed** — `./Test -t lint` instead of full suite
3. **Unresolvable dependency** — required tooling not available AND no graceful fallback

These are the only valid skip cases. Isolation, concurrency, and environment conflicts are solved by design.

## Agent Integration

When an agent encounters a repo with a `Test` script:

```bash
# Full verification
cd /path/to/repo && ./Test -C 2>&1 | tee test-output.log
tail -1 test-output.log | grep -q '^OK (' && echo "PASS" || echo "FAIL"

# Prod smoke test
ENV=prod ./Test 2>&1 | tee smoke-output.log
```

When an agent **creates** a new project:

1. Create `Test` at repo root, `chmod +x`
2. Add trap-based pass/fail boilerplate
3. Add environment detection (prod path/ENV var, else test)
4. Export `RUNTIME_ENV` so the program selects correct config
5. Add isolation: `PROJDIR`, `.build/`, clean build
6. Add bootstrap step (venv creation, dep install)
7. Add test phases with `echo "===== Phase Name"` headers
8. Add prod branch for read-only smoke tests
9. End with `PASSED=true` and `echo "OK ($(elapsed)s)"`
10. Support `-C` for clean rebuilds

## Design Principles Summary

- **Idempotent** — `./Test` == `rm -rf .build/ && ./Test`, always
- **Isolated** — per-checkout `.build/`, gitignored, disposable
- **Environment-aware** — auto-detects prod vs test, exports `RUNTIME_ENV`
- **Self-bootstrapping** — brings up everything from scratch, no manual setup
- **Production-safe** — smoke tests in prod are read-only, never clobber
- **Language-agnostic** — one convention, any stack

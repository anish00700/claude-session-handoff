<!-- A worked example, written to the standard in SKILL.md. The project is invented;
     read it for tone, specificity, and granularity, not for its technical content. -->

# Session handoff — read this first in any new session

Last updated: 2026-03-14 (end of session, ahead of a `/clear`). Read this, then `CLAUDE.md`,
then `docs/adr/0009_rate_limiting.md`, before touching the limiter. This file **supersedes**
any earlier handoff — the prior one (dated 2026-03-11) is stale, and its claim that the Lua
script is "done" is wrong; see section 2 below.

## State in one line

**The Redis-backed rate limiter is written, tested, and open as a PR, but the production
cutover is gated behind a flag that is still off.** Work is on `feat/redis-rate-limiter`,
tip `9c41f0a`, head of [PR #482](https://github.com/example-org/orchard-api/pull/482) — CI
green, one approval, not merged. The one thing standing between here and merge is a load
test at 3× peak that nobody has run yet.

## Where the work lives

- **Main checkout** (`~/src/orchard-api`, branch `feat/redis-rate-limiter`, tip `9c41f0a`):
  clean, pushed. All limiter work happens here.
- **`ops/` submodule**, pinned at `f0a12de`: Terraform for the Redis cluster. The cluster is
  already provisioned and reachable. **Do not bump this pin on this branch** — a bump drags
  in an unrelated VPC peering change that is still under review in its own repo.

## What happened this session (chronological)

### 1. Replaced the in-process token bucket

`internal/ratelimit/bucket.go` held per-instance state, so the effective limit scaled with
replica count — the bug in [#455](https://github.com/example-org/orchard-api/issues/455).
Replaced with a Redis-backed sliding window in `internal/ratelimit/redis_window.go`. Old
implementation deleted, not deprecated; nothing else imported it (verified with `grep -r`).

### 2. First Lua implementation had a race — reverted

The initial script did `ZCARD` then `ZADD` as two round trips. Under concurrent requests to
the same key, both calls could read a count below the limit and both admit — the exact
over-admission the change was meant to fix. It passed unit tests because those exercised one
goroutine at a time. Caught only after writing `TestConcurrentAdmit` with 200 goroutines,
which failed ~40% of runs.

Reverted in `c72b1aa`. **The mechanism matters: any implementation that reads the count and
writes the entry in separate round trips is wrong, no matter how small the window between
them.** Don't reintroduce a "simpler" two-call version.

### 3. Rewrote as one atomic script

`internal/ratelimit/window.lua` now does prune, count, and conditional insert in a single
`EVALSHA`, so admission is atomic per key. `TestConcurrentAdmit` passes 500/500 runs.
Committed in `4e8b3d1`.

### 4. Feature flag and fallback

Cutover is behind `RATELIMIT_BACKEND` (`memory` | `redis`), defaulting to `memory`. If Redis
is unreachable the limiter **fails open** and logs at WARN. This was a deliberate call — see
settled decisions.

## Current exact state (verified this session — don't re-check without reason)

- **Branch** `feat/redis-rate-limiter`, clean, pushed, tip `9c41f0a`.
- **PR #482**: OPEN, mergeable, CI green, approved by one reviewer. Not merged — waiting on
  the load test, not on review.
- **`go test ./...`**: passes, including `TestConcurrentAdmit` at 500 iterations.
- **`RATELIMIT_BACKEND` in production**: `memory`. The Redis path has never served real
  traffic.

## Decisions already settled (don't re-ask)

- **Fail open, not closed**, when Redis is unreachable. A limiter outage degrading into "no
  limiting" is survivable; one that rejects all traffic is an outage of its own. Confirmed
  with the on-call lead.
- **Sliding window, not token bucket.** Bucket refill is cheaper but the burst behavior was
  what customers complained about in #455. Revisit only with new evidence.
- **One Redis key per `(tenant, route)` pair**, not per tenant. Chosen after the per-tenant
  version made a single noisy route starve the rest of a tenant's quota.
- **No client-side jitter on retry-after** — the gateway already jitters. Adding it in both
  places was tried and produced visibly wrong `Retry-After` headers.

## Explicitly NOT done / still open

- **Load test at 3× peak** — not started. Needs the staging Redis, which is provisioned but
  has never taken more than smoke traffic. This is the merge blocker.
- **Metrics** — `ratelimit_admitted_total` and `ratelimit_rejected_total` are emitted, but
  no dashboard or alert consumes them yet. Deliberate: wait until the flag is on somewhere.
- **The production cutover itself** — flipping `RATELIMIT_BACKEND` to `redis` is the team's
  call, not something to do proactively.
- **`ops/` submodule pin bump** — deferred until the VPC peering change lands upstream.

## Operational notes for whoever picks this up

- **`make test-integration` needs a local Redis**: `docker compose up -d redis` first, or it
  fails with a misleading `connection refused` that looks like a code bug.
- **`EVALSHA` returns `NOSCRIPT` after a Redis restart.** The client reloads the script
  automatically, but the first request post-restart logs an error that is expected and not
  worth chasing.
- **Staging Redis is `orchard-staging-001.cache.internal:6379`** — not the value in
  `.env.example`, which still points at the decommissioned `-000` host. Fixing that file is
  unclaimed.
- **Fuller design rationale** is in `docs/adr/0009_rate_limiting.md`, including the two
  approaches rejected before this one. Read it before proposing a redesign.

## Next step

Run the 3× peak load test against staging, with `RATELIMIT_BACKEND=redis`. Everything needed
is provisioned and the flag already works — this is measurement, not construction. Do not
re-litigate sliding-window vs token-bucket, and do not "simplify" the Lua script into
separate read and write calls; both are settled above. Once numbers exist, PR #482 is ready
for a merge decision by the team.

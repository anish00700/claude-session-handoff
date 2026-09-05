# Session handoff — read this first in any new session

Last updated: YYYY-MM-DD (end of session, ahead of a `/clear`). Read this, then `CLAUDE.md`,
then <any project-specific style or convention file>, before doing anything in this repo.
This file **supersedes** any earlier handoff — the prior one (dated YYYY-MM-DD) is now stale.

<!-- Adjust the reading order to what this repo actually has. Drop the supersedes sentence
     on a first handoff. -->

## State in one line

**<Where the work stands, in bold — the one sentence someone reads if they read nothing
else.>** <A second sentence for the branch/PR/worktree it lives on and what comes next.>

## Where the work lives

<!-- Only include when more than one checkout, worktree, or branch is in play. Otherwise cut. -->

- **Main checkout** (`/abs/path`, branch `name`): state, pushed or not, tip SHA, what this
  branch is for, and what must **not** be done here.
- **Worktree** (`/abs/path`, branch `name`, tip `SHA`): same, plus which one the user
  resumes in.

## What happened this session (chronological)

### 1. <Short title of the first meaningful thing>

What was done, the commit it landed in, and the outcome. If it was reverted or rejected,
say by whom and why — the reason is the load-bearing part.

### 2. <Next thing>

Include decisions made mid-stream and what they superseded. Where the user gave explicit
instructions that override an earlier plan, quote the substance of them.

### 3. <A failed attempt, if there was one>

What was tried, why it seemed right, how it failed, and what the corrected approach was.
Name the mechanism — "this replaced the hosted default dictionary rather than layering on
top of it" — not just "it didn't work".

## Current exact state (verified this session — don't re-check without reason)

- **<Checkout / branch>**: clean or dirty, pushed or not, tip `SHA`.
- **<PR #n>**: state, mergeable, CI status, and whether merging is decided.
- **<Checks>**: which commands pass, and as of when.

## Decisions already settled (don't re-ask)

- <Decision, then the compressed reason.> Confirmed with the user.
- <Cross-cutting rule that applies to all remaining work.>
- <A convention chosen over an alternative — name the alternative that was rejected.>

## Explicitly NOT done / still open

- **<Phase or task not started>** — what it needs, and what already exists to build on.
- **<Decision the user hasn't made>** — state that it is theirs to make, not to do
  proactively.
- <Parked items carried forward from earlier sessions that are still true.>

## Operational notes for whoever picks this up

- <Broken tooling and the workaround.>
- <A value that differs from the documented default — real port, real path, real flag.>
- <Where fuller detail lives: plan file path, PR thread, issue link — and what's in it.>
- <Tools installed or config changed this session that the next session can rely on.>

## Next step

<The single first action, and where to do it.> <What is already settled and must not be
re-derived.> <What the session should wait for from the user, if anything.>

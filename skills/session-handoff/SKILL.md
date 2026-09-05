---
name: session-handoff
description: Write or refresh SESSION_HANDOFF.md — the document the next session reads first so it can resume work without re-deriving anything. Use at the end of a working session, before /clear or /compact, when context is running low, or when the user says "wrap up", "write the handoff", "hand this off", "I'm about to clear", "save state". Also use when asked to update, refresh, or supersede an existing handoff.
---

# Session handoff

Produce one file, `SESSION_HANDOFF.md`, that a fresh session with zero context can read
and immediately continue the work — without re-deriving decisions, re-checking state, or
repeating dead ends.

The test for every line: **would a competent stranger, holding only this file and the
repo, do the right next thing?** If a line doesn't move them toward that, cut it.

## 1. Read the old handoff first

If `SESSION_HANDOFF.md` already exists, read it before writing. The new file **replaces**
it in full — never append a new session's notes to the bottom, and never leave two
handoffs side by side.

Carry forward everything from the old file that is still true and still open. Drop what
this session resolved. Say explicitly in the header that this file supersedes the earlier
one, with the earlier one's date.

## 2. Verify state — do not write it from memory

Your recollection of branch names, SHAs, and whether checks passed drifts over a long
session. Confirm before writing:

```bash
git status --short --branch && git log --oneline -15 && git worktree list
```

Also check open PRs (`gh pr status`, or `gh pr view <n> --json state,mergeable,mergeStateStatus,statusCheckRollup`)
when any exist.

Re-run tests, lint, or build **only** if the handoff will state their result and code has
changed since they last ran. If a check hasn't been run since the last edit, say so — write
"not re-run since commit `abc1234`" rather than asserting it passes.

## 3. Where the file goes

Repo root, as `SESSION_HANDOFF.md`. If the user works across a main checkout plus git
worktrees, put it in the checkout they will resume in, and say in the file which one that
is.

Don't commit it unless the user asks. If they want it out of git, offer `.gitignore` or
`.claude/SESSION_HANDOFF.md` — their call, mention it once.

## 4. Structure

Follow `reference/template.md`. Sections, in order:

| Section | Carries |
|---|---|
| Header line | Date (absolute), why it was written, what to read after this, what it supersedes |
| **State in one line** | Where the work stands right now, in bold, one or two sentences |
| **Where the work lives** | Checkouts, worktrees, branches, key paths — only if more than one location is in play |
| **What happened this session** | Numbered, chronological. Include attempts that failed and *why* |
| **Current exact state** | Verified facts, marked as verified so nobody re-checks them |
| **Decisions already settled** | Confirmed choices, marked don't-re-ask |
| **Explicitly NOT done / still open** | Named gaps, plus what is undecided and waiting on the user |
| **Operational notes** | Gotchas, broken tooling, real port numbers, workarounds discovered |
| **Next step** | The single thing to do first, and what not to redo |

Drop a section only when it would be genuinely empty. "Decisions already settled" and
"Explicitly NOT done" are the two that save the most work downstream — fight to fill them.

`reference/example.md` is a full worked example written to this standard. Read it when the
template alone doesn't settle a question of tone or granularity.

## 5. What earns a place

- **Exact identifiers.** Commit SHAs, PR URLs, absolute paths, branch names, real port
  numbers, file names. Never "the recent commit" or "the config file".
- **Dead ends and why they failed.** A fix that backfired is worth more than a fix that
  worked — it stops the next session from trying it again.
- **Explicit negatives.** "Do not touch `admin_guide/` on this branch." "PR merge is the
  user's call, not decided." Absences are invisible unless named.
- **Settled decisions with the reasoning compressed.** Enough that the next session
  defends the decision rather than reopening it.
- **Pointers, not copies.** If detail lives in a plan file, PR thread, or issue, link it
  and say what's there. Duplicating it makes both stale.
- **Absolute dates.** "2026-09-02", never "yesterday" or "last week".

## 6. What doesn't

- Anything `git log` or `git diff` already tells you. The value here is what the repo
  *cannot* record: intent, rejected options, verbal decisions, tool quirks.
- Narration of your own process ("I then searched for…"). State conclusions.
- Praise, self-assessment, or summary of how the session went.
- Secrets, tokens, or credentials — even ones you saw in output.
- Speculation dressed as fact. If something is a guess, label it: "possibly not a real
  shipped feature — confirm before authoring".

## 7. Length

Aim for 60–120 lines. Short enough that the next session actually reads it before
starting; long enough to carry the decisions. If it runs past ~150 lines, the overflow
usually belongs in a linked plan file, not here.

## 8. Close out

Tell the user the file is written and where. If the session ended with something
undecided or waiting on them, restate that one item — it's the thing most likely to be
lost across a `/clear`.

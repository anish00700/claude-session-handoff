---
name: session-handoff
description: Write or refresh SESSION_HANDOFF.md so the next session resumes without re-deriving anything. Use when wrapping up a session, before /clear or /compact, when context runs low, or on "write the handoff", "hand this off", "save state".
---

# Session handoff

Write `SESSION_HANDOFF.md` so a fresh session with zero context can resume the work without
re-deriving decisions, re-checking state, or repeating dead ends.

Test every line: **would a stranger holding only this file and the repo do the right next
thing?** If not, cut it.

**One project per handoff.** Record only what belongs to the project this file sits in.
Sessions range wider — another repo, a client's codebase, an unrelated errand — and none of it
belongs here: this file gets committed, cloned, and injected into other people's sessions, so a
stray employer or client name travels with it. Cross-project work gets one neutral line
("paused to help on an unrelated repo"); the details go in *that* project's handoff.

## 1. Read the existing handoff first

If one exists, read it. The new file **replaces** it — never append, never leave two side by
side. Carry forward what is still open, drop what this session resolved, and say in the header
which dated handoff it supersedes.

**If none exists, write one from scratch from this project's verified state** (step 2). Never
seed it from elsewhere — not the invented project in `reference/example.md`, not the literal
placeholders in `reference/template.md`, never another repo's handoff. A first handoff has no
*supersedes* line and covers this session only; if you can't verify a thing, omit it.

## 2. Verify — don't recall

Branch names, SHAs and check results drift over a long session. Before writing:

```bash
git status --short --branch && git log --oneline -15 && git worktree list
```

Add `gh pr view <n> --json state,mergeable,statusCheckRollup` when PRs are open.

Re-run tests only if the handoff states their result and code changed since. Otherwise write
"not re-run since `abc1234`" rather than asserting a pass.

## 3. Where it goes

The **session's working directory**, as `SESSION_HANDOFF.md`. Never a parent, never a repo root
you aren't sitting in, never a scratch directory. Across worktrees, use the one being resumed
and name it in the file.

Don't commit it unless asked. Offer `.gitignore` once if they'd rather it stay out of git.

## 4. Point CLAUDE.md at it

Claude Code auto-loads `CLAUDE.md`, never `SESSION_HANDOFF.md` — a handoff nothing points to is
one nobody reads. In the handoff's own directory: if `CLAUDE.md` mentions it, leave it alone;
if it exists without a mention, append a short pointer block wrapped in
`<!-- session-handoff:begin -->` / `<!-- session-handoff:end -->`; if absent, create it with
that block. Use those exact markers — the plugin's hook keys off them, so the two stay
idempotent instead of writing competing pointers. A `CLAUDE.md` holding only the pointer is
fine — don't pad it with an invented project description.

**If the handoff is in a subdirectory of a git repo, add a second pointer to the root
`CLAUDE.md`** naming the relative path. Without it a session started at the repo root never
learns the handoff exists.

## 5. Sections, in order

| Section | Carries |
|---|---|
| Header | Absolute date, what to read next, which handoff this supersedes |
| **State in one line** | Where things stand, for someone who reads nothing else |
| **Where the work lives** | Checkouts, worktrees, branches, key paths — only if several are in play |
| **What happened this session** | Numbered, chronological, including attempts that failed and why |
| **Current exact state** | Verified facts, marked verified so nobody re-checks them |
| **Decisions already settled** | Confirmed choices, marked don't-re-ask |
| **Explicitly NOT done / still open** | Named gaps, and what is waiting on the user |
| **Operational notes** | Gotchas, broken tooling, real ports, workarounds |
| **Next step** | The single first action, and what not to redo |

Drop a section only when it would be genuinely empty. **Decisions already settled** and
**Explicitly NOT done** save the most work downstream — fight to fill them.

## 6. Include

- **Exact identifiers** — SHAs, PR URLs, absolute paths, branches, real ports. Never "the
  recent commit".
- **Dead ends, with the mechanism of the failure** — what stops the next session retrying them.
- **Explicit negatives** — "don't touch `X/` on this branch", "the merge is not decided".
  Absences are invisible unless named.
- **Settled decisions with compressed reasoning**, so they get defended, not reopened.
- **Pointers, not copies** — link the plan file or PR thread and say what is in it.
- **Absolute dates** — "2026-09-02", never "yesterday".

## 7. Omit

Anything `git log` or `git diff` already says; narration of your own process; praise or
self-assessment; secrets and tokens; speculation unless labelled a guess; **anything belonging
to a different project** — see the one-project rule above.

## 8. Length

60–120 lines. Past ~150 the overflow belongs in a linked plan file, not here.

## 9. Close out

Say where the file is and whether you touched `CLAUDE.md`. Restate anything left undecided —
that is what a `/clear` loses.

---

The table above is normally enough. Only if it isn't, load `reference/template.md` (a literal
skeleton, ~800 tokens) or `reference/example.md` (a worked handoff for calibrating tone,
~1,600 tokens). **Copy their shape, never their content** — the example's project, paths and
SHAs are invented; the template's angle-bracket placeholders are prompts, not text to emit.

# session-handoff

A Claude Code skill that writes `SESSION_HANDOFF.md` — the document the next session reads
first so it can resume work **without re-deriving decisions, re-checking state, or repeating
dead ends**.

Long sessions end in one of two ways: a `/clear`, or a context window that quietly fills up.
Either way the next session starts blind. It re-reads files you already read, re-asks
questions you already answered, and sometimes retries the exact approach that failed three
hours ago. A handoff file fixes that — but only if it records the things a repo *can't*:
intent, rejected options, verbal decisions, and tool quirks.

## Install

```bash
claude plugin marketplace add anish00700/claude-session-handoff
```

```bash
claude plugin install session-handoff@claude-session-handoff
```

## Use

The skill triggers on its own when you say things like "wrap up", "write the handoff",
"I'm about to clear", or "save state" — and when context is running low. To invoke it
directly:

```bash
/session-handoff
```

It writes `SESSION_HANDOFF.md` to **the directory you're working in** — never a parent,
never a repo root you aren't sitting in. On later sessions it reads the existing file,
carries forward what's still open, and **replaces** it — handoffs never stack up.

## It loads itself back

Claude Code auto-loads `CLAUDE.md` but not `SESSION_HANDOFF.md`, so a handoff nothing points
to is a handoff nobody reads. The plugin closes that gap in two ways, both automatic:

**Hooks that ship with the plugin.** On `SessionStart` and after a compaction, the handoff for
your working directory is injected straight into context — no prompting, no remembering. Other
handoffs elsewhere in the repo are listed by path only, so a large repo costs a line rather
than a page. When a handoff is written, a `CLAUDE.md` pointer is created or updated beside it,
and — if the handoff is in a subdirectory — a second pointer goes in the **repo root**
`CLAUDE.md`, so a session started at the root still finds it. All of it is idempotent and a
silent no-op when there's no handoff.

**The skill itself** applies the same `CLAUDE.md` rule when it writes, so the behaviour holds
even where hooks are disabled.

Requires `git` and `python3` (both near-universal on a machine running Claude Code). Without
`python3` the hooks no-op silently rather than erroring.

## What it produces

A file with these sections, in order:

| Section | Carries |
|---|---|
| Header | Absolute date, what to read next, what this supersedes |
| **State in one line** | Where things stand, for someone reading nothing else |
| **Where the work lives** | Checkouts, worktrees, branches, key paths |
| **What happened this session** | Chronological — including attempts that failed, and why |
| **Current exact state** | Verified facts, marked so nobody re-checks them |
| **Decisions already settled** | Confirmed choices, marked don't-re-ask |
| **Explicitly NOT done / still open** | Named gaps, and what's waiting on you |
| **Operational notes** | Gotchas, broken tooling, real port numbers, workarounds |
| **Next step** | The single first action, and what not to redo |

See [`reference/example.md`](skills/session-handoff/reference/example.md) for a full worked
example, and [`reference/template.md`](skills/session-handoff/reference/template.md) for the
skeleton.

## The design, in short

Three choices do most of the work:

1. **Verify, don't recall.** The skill runs `git status`, `git log`, `git worktree list`, and
   `gh pr view` before writing. Your memory of which branch is pushed drifts over a long
   session; the output doesn't. Checks that haven't run since the last edit get written as
   "not re-run since `abc1234`" rather than asserted as passing.

2. **Record dead ends and their mechanism.** A fix that backfired is worth more than one that
   worked, because it's the one the next session will otherwise retry. "This replaced the
   default dictionary rather than layering onto it" beats "that didn't work."

3. **Name the negatives.** "Do not touch this directory on this branch." "The merge is your
   call, not decided." Absences are invisible unless written down.

## Contributing

Issues and PRs welcome. If you change the section list in `SKILL.md`, update
`reference/template.md` to match — they're meant to stay in lockstep.

## License

MIT — see [LICENSE](LICENSE).

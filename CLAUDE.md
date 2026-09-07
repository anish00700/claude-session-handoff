# claude-session-handoff

**Read `SESSION_HANDOFF.md` first if it exists.** It carries the state, settled decisions,
and open items from the previous session — reading it avoids re-deriving work that is
already done.

This repository is a Claude Code plugin. It publishes one skill, `session-handoff`, which
writes and maintains `SESSION_HANDOFF.md` in whatever repository it is used in.

## Layout

```
.claude-plugin/
  plugin.json          plugin manifest
  marketplace.json     this repo doubles as its own marketplace (source: "./")
skills/session-handoff/
  SKILL.md             the skill itself — triggers, rules, section list
  reference/
    template.md        the section skeleton
    example.md         a worked example (invented project — keep it that way)
hooks/
  hooks.json           auto-discovered at the plugin root; no manifest key points at it
hooks-handlers/
  inject-handoff.sh    SessionStart + PostCompact — injects the handoff into context
  claudemd-pointer.sh  PostToolUse (Write|Edit) — keeps CLAUDE.md pointing at the handoff
docs/
  install-guide.html   source for the published install-guide PDF
```

## Conventions

- **`SKILL.md` and `reference/template.md` stay in lockstep.** If you change the section
  list in one, change it in the other.
- **`reference/example.md` must stay generic.** This repository is public. The example is
  deliberately an invented project — never replace it with a real internal handoff.
- **Bump `version` in `plugin.json` when the skill changes.** `claude plugin tag` validates
  that the manifest and the marketplace entry agree before tagging a release.
- **`SESSION_HANDOFF.md` in this repo is gitignored on purpose — don't re-add it.** It is a
  local development artifact. Tracked, it would ship to everyone who clones, and the
  `SessionStart` hook would inject this project's build notes into their session. That is
  exactly the cross-project contamination `SKILL.md` forbids; the plugin must not commit it.
  The public worked example is `reference/example.md`.

## Validate before pushing

```sh
claude plugin validate . --strict
claude plugin validate skills --strict
claude plugin validate .claude-plugin/plugin.json
```

The first call validates the marketplace manifest, not the plugin manifest — that is why the
third is separate rather than redundant.

**The plugin-manifest check is deliberately run without `--strict`.** It emits one warning:
`CLAUDE.md at the plugin root is not loaded as project context`. That is true and intended —
this file exists for people working *in* this repository, not to ship context to people who
install the plugin (skills do that). Under `--strict` the warning becomes an error, so don't
add `--strict` there and don't delete `CLAUDE.md` to silence it. Any *other* warning from
that command is a real problem.

## Not to be modified without reason

- `LICENSE` — MIT, referenced by both manifests.
- The `name` fields in `plugin.json` and `marketplace.json` — changing either breaks
  `claude plugin install session-handoff@claude-session-handoff` for existing users.

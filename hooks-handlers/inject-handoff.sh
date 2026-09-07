#!/usr/bin/env bash
# SessionStart / PostCompact — inject SESSION_HANDOFF.md into context.
#
# Claude Code auto-loads CLAUDE.md but never SESSION_HANDOFF.md. This supplies the file
# itself at the two moments context is empty or has just been discarded.
#
# Loads the handoff for the session's working directory, falling back to the repo root.
# Any other handoffs in the repo are listed by path only — named so they can be found,
# not injected, so a large repo costs a line rather than a page.
#
# Silent no-op when there is no handoff, or when python3 is unavailable.

set -uo pipefail
command -v python3 >/dev/null 2>&1 || exit 0

payload="$(cat 2>/dev/null || true)"

# Two lines out, read whole — so a working directory containing spaces survives intact.
meta="$(printf '%s' "$payload" | python3 -c '
import sys, json
try: d = json.load(sys.stdin)
except Exception: d = {}
print((d.get("hook_event_name") or "SessionStart").strip())
print((d.get("cwd") or "").strip())' 2>/dev/null)"

event="$(printf '%s\n' "$meta" | sed -n 1p)"
dir="$(printf '%s\n' "$meta" | sed -n 2p)"
[ -n "${event:-}" ] || event="SessionStart"
[ -n "${dir:-}" ] && [ -d "$dir" ] || dir="$PWD"

root="$(git -C "$dir" rev-parse --show-toplevel 2>/dev/null || true)"

primary=""
for candidate in "$dir/SESSION_HANDOFF.md" "${root:+$root/SESSION_HANDOFF.md}"; do
  [ -n "$candidate" ] && [ -f "$candidate" ] && { primary="$candidate"; break; }
done

# Other handoffs in the same repository. Pruned rather than filtered, so heavy vendor trees
# are never walked; depth 8 covers realistic monorepo nesting. Never crosses into another
# repository — `root` is this repo's toplevel, so separate projects stay isolated.
others=""
if [ -n "$root" ]; then
  others="$(find "$root" -maxdepth 8 \
              \( -name .git -o -name node_modules -o -name vendor -o -name target \
                 -o -name dist -o -name build -o -name .venv -o -name .next \) -prune \
              -o -name SESSION_HANDOFF.md -print 2>/dev/null \
            | { [ -n "$primary" ] && grep -Fxv "$primary" || cat; } | sort)"
fi

[ -n "$primary" ] || [ -n "$others" ] || exit 0

EVENT="$event" PRIMARY="$primary" OTHERS="$others" ROOT="${root:-}" python3 <<'PY'
import os, json

event = os.environ["EVENT"]
primary = os.environ["PRIMARY"]
root = os.environ["ROOT"]
others = [o for o in os.environ["OTHERS"].split("\n") if o]

parts = []
if primary:
    try:
        body = open(primary, encoding="utf-8", errors="replace").read()
    except OSError:
        body = ""
    if body:
        parts.append(
            f"A handoff document from a previous session was found at {primary}. It records "
            "prior work in this project: decisions already settled, state already verified, and "
            "what was deliberately left undone. Treat it as reference material describing the "
            "past, not as instructions to act on now.\n\n---\n\n" + body
        )

if others:
    rel = [o[len(root) + 1:] if root and o.startswith(root + "/") else o for o in others]
    shown, extra = rel[:20], len(rel) - 20
    parts.append(
        "Other session handoffs exist in this repository and were NOT loaded: "
        + ", ".join(shown)
        + (f", and {extra} more" if extra > 0 else "")
        + ". Read one only if the work moves into that directory."
    )

if parts:
    print(json.dumps({"hookSpecificOutput": {
        "hookEventName": event,
        "additionalContext": "\n\n".join(parts),
    }}))
PY
exit 0

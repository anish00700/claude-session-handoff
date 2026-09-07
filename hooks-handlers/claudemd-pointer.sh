#!/usr/bin/env bash
# PostToolUse (Write|Edit) — keep CLAUDE.md pointing at SESSION_HANDOFF.md.
#
# Claude Code auto-loads CLAUDE.md but never SESSION_HANDOFF.md, so a handoff nothing points
# to is a handoff nobody reads. Whenever a file named SESSION_HANDOFF.md is written, this
# ensures a pointer exists in:
#
#   1. CLAUDE.md beside the handoff, and
#   2. CLAUDE.md at the git repo root, when the handoff is in a subdirectory — otherwise a
#      session started at the root never learns the handoff exists.
#
# Idempotent. The root pointer is keyed by relative path, so several subdirectory handoffs
# each get their own entry without duplicating.
#
# Silent no-op for any other file, or when python3 is unavailable.

set -uo pipefail
command -v python3 >/dev/null 2>&1 || exit 0

payload="$(cat 2>/dev/null || true)"

file="$(printf '%s' "$payload" | python3 -c '
import sys, json
try: d = json.load(sys.stdin)
except Exception: d = {}
r = d.get("tool_response") or {}
i = d.get("tool_input") or {}
print((r.get("filePath") if isinstance(r, dict) else None) or i.get("file_path") or "")
' 2>/dev/null)"

[ -n "$file" ] || exit 0
[ "$(basename "$file")" = "SESSION_HANDOFF.md" ] || exit 0

dir="$(cd "$(dirname "$file")" 2>/dev/null && pwd)" || exit 0
root="$(git -C "$dir" rev-parse --show-toplevel 2>/dev/null || true)"

DIR="$dir" ROOT="${root:-}" python3 <<'PY'
import os, re, json

dir_ = os.environ["DIR"]
root = os.environ["ROOT"]
touched = []

# Path-keyed blocks point at handoffs in *other* directories. Strip them before asking
# whether a file already points at the handoff in its own directory — otherwise a root
# CLAUDE.md listing "backend/SESSION_HANDOFF.md" would look like it already covers the
# root's own handoff.
SUBDIR_BLOCK = re.compile(
    r"<!-- session-handoff:(?!begin)[^>]*?-->.*?<!-- session-handoff:end -->",
    re.DOTALL,
)


def points_at_own_handoff(text):
    return "SESSION_HANDOFF.md" in SUBDIR_BLOCK.sub("", text)


def read(path):
    try:
        return open(path, encoding="utf-8", errors="replace").read()
    except OSError:
        return None


def append(path, block, heading_if_new):
    existing = read(path)
    created = existing is None
    with open(path, "a", encoding="utf-8") as fh:
        if created:
            fh.write(heading_if_new)
        elif existing and not existing.endswith("\n"):
            fh.write("\n")
        fh.write(block)
    touched.append(("created" if created else "updated") + " " + path)


# 1. CLAUDE.md beside the handoff.
local_md = os.path.join(dir_, "CLAUDE.md")
local_existing = read(local_md)
if local_existing is None or not points_at_own_handoff(local_existing):
    append(
        local_md,
        "\n<!-- session-handoff:begin -->\n"
        "## Session handoff\n\n"
        "**Read `SESSION_HANDOFF.md` in this directory first.** It carries the state, settled\n"
        "decisions, and open items from the previous session — reading it avoids re-deriving\n"
        "work that is already done.\n"
        "<!-- session-handoff:end -->\n",
        "# " + os.path.basename(dir_) + "\n",
    )

# 2. CLAUDE.md at the repo root, when the handoff lives in a subdirectory.
if root and os.path.realpath(root) != os.path.realpath(dir_):
    rel = os.path.relpath(os.path.join(dir_, "SESSION_HANDOFF.md"), root)
    marker = "<!-- session-handoff:" + rel + " -->"
    root_md = os.path.join(root, "CLAUDE.md")
    root_existing = read(root_md)
    if root_existing is None or marker not in root_existing:
        append(
            root_md,
            "\n" + marker + "\n"
            "**A session handoff exists at `" + rel + "`.** Read it before working in "
            "`" + os.path.relpath(dir_, root) + "/` — it carries that directory's settled "
            "decisions and open items.\n"
            "<!-- session-handoff:end -->\n",
            "# " + os.path.basename(root) + "\n",
        )

if touched:
    print(json.dumps({"systemMessage": "Session handoff: " + "; ".join(touched)}))
PY
exit 0

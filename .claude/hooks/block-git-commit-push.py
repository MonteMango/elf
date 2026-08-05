#!/usr/bin/env python3
"""PreToolUse hook (Bash): block `git commit` / `git push`.

CLAUDE.md's Git Policy reserves committing and pushing for the user
(Vitalii) — Claude stages/edits files but never runs `git commit` or
`git push` itself. This enforces that at the harness level instead of
relying on Claude reading and remembering the rule.
"""
import json
import re
import shlex
import sys

GLOBAL_FLAGS_WITH_VALUE = {"-C", "-c", "--git-dir", "--work-tree", "--namespace"}
BLOCKED_SUBCOMMANDS = {"commit", "push"}


def find_blocked_subcommand(tokens):
    for i, tok in enumerate(tokens):
        if tok != "git":
            continue
        j = i + 1
        while j < len(tokens):
            t = tokens[j]
            if t.startswith("-"):
                j += 2 if t in GLOBAL_FLAGS_WITH_VALUE else 1
                continue
            if t in BLOCKED_SUBCOMMANDS:
                return t
            break
    return None


def main():
    try:
        payload = json.load(sys.stdin)
    except json.JSONDecodeError:
        print("{}")
        return

    command = payload.get("tool_input", {}).get("command", "") or ""

    blocked = None
    for chunk in re.split(r"&&|\|\||[;|]", command):
        try:
            tokens = shlex.split(chunk)
        except ValueError:
            tokens = chunk.split()
        blocked = find_blocked_subcommand(tokens)
        if blocked:
            break

    if blocked:
        reason = (
            f"Blocked: `git {blocked}` is not allowed here. Only Vitalii commits/pushes "
            "in this repo (CLAUDE.md §Git Policy) — stage or leave changes as-is and "
            "tell the user what would have been committed so they can run it themselves."
        )
        print(json.dumps({
            "hookSpecificOutput": {
                "hookEventName": "PreToolUse",
                "permissionDecision": "deny",
                "permissionDecisionReason": reason,
            }
        }))
    else:
        print("{}")


if __name__ == "__main__":
    main()

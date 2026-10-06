#!/usr/bin/env bash
# PreToolUse hook for `git commit` and `git push` (Bash tool).
# Keeps CLAUDE.md in sync with the code by asking Claude to review it first.
#
# Usage: claude-md-check.sh commit|push
#
# commit: block the first attempt (per 10 minutes) and tell Claude to review
#         CLAUDE.md, update and `git add` it if needed, then retry. If CLAUDE.md
#         is already staged, the commit goes through.
# push:   block only if CLAUDE.md has uncommitted changes, so it isn't left behind.
#
# No jq dependency. Exits 0 (allow) whenever it can't tell what to do.

mode="$1"
root="${CLAUDE_PROJECT_DIR:-$(pwd)}"
cd "$root" 2>/dev/null || exit 0

# Not a git repo yet, or no CLAUDE.md: nothing to do.
git rev-parse --git-dir >/dev/null 2>&1 || exit 0
[ -f CLAUDE.md ] || exit 0

deny() {
  # $1 must not contain double quotes or backslashes.
  printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"%s"}}\n' "$1"
  exit 0
}

case "$mode" in
  commit)
    # CLAUDE.md already part of this commit.
    git diff --cached --name-only | grep -qx 'CLAUDE.md' && exit 0

    marker="$root/.claude/.claude-md-reviewed"
    # Reviewed within the last 10 minutes: allow once and reset.
    if [ -n "$(find "$marker" -mmin -10 2>/dev/null)" ]; then
      rm -f "$marker"
      exit 0
    fi
    touch "$marker"
    deny "Before committing, review CLAUDE.md against the changes being committed (git diff --cached). If the stack, file layout, conventions, commands, or content rules changed, update CLAUDE.md and git add it so it lands in this commit. If nothing needs updating, retry the same commit unchanged."
    ;;
  push)
    if [ -n "$(git status --porcelain -- CLAUDE.md 2>/dev/null)" ]; then
      deny "CLAUDE.md has uncommitted changes. Commit it before pushing."
    fi
    ;;
esac

exit 0

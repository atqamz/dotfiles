#!/usr/bin/env bash
# UserPromptSubmit hook: warn when context passes a token threshold.
#
# Reads the bridge file written by statusline-command.sh
# (/tmp/claude-ctx-<session>.json), which carries the live token count.
# Over THRESHOLD it emits BOTH a user-facing banner (systemMessage) and a
# reminder injected into Claude's context (additionalContext) telling it to
# suggest /clear or /compact and to chunk remaining work.

THRESHOLD=100000

input=$(cat)
session=$(echo "$input" | jq -r '.session_id // empty' 2>/dev/null)
[ -z "$session" ] && exit 0

bridge="/tmp/claude-ctx-${session}.json"
[ -f "$bridge" ] || exit 0

tokens=$(jq -r '.tokens // 0' "$bridge" 2>/dev/null)
[[ "$tokens" =~ ^[0-9]+$ ]] || exit 0
[ "$tokens" -lt "$THRESHOLD" ] && exit 0

tk=$(awk "BEGIN{printf \"%.0f\", $tokens/1000}")

jq -n --arg tk "$tk" '{
  systemMessage: ("Context ~" + $tk + "K (>100K). /clear for a new task, /compact to keep this one."),
  hookSpecificOutput: {
    hookEventName: "UserPromptSubmit",
    additionalContext: ("Context is ~" + $tk + "K tokens, past 100K. Proactively tell the user their options: /clear if this prompt starts unrelated work, /compact to continue the current thread. Keep remaining work in chunks small enough to fit ~100K of context: finish one self-contained chunk, then recommend compact/clear before starting the next.")
  }
}'

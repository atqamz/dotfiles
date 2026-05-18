#!/usr/bin/env bash
# graphify-sync: rebuild graphify-memory + graphify-personal graphs, push ~/raw.
# Triggered by graphify-sync.timer (daily) or run manually.
# Requires GEMINI_API_KEY (loaded via systemd EnvironmentFile=%h/.config/graphify/env
# or sourced from %h/.config/graphify/env when run interactively).

set -uo pipefail

SRC_MEMORY="$HOME/.claude/projects/"
MEMORY_WS="$HOME/.graphify/memory-workspace"
MEMORY_DST="$MEMORY_WS/projects/"
RAW="$HOME/raw"

log() { echo "[graphify-sync] $*"; }
warn() { echo "[graphify-sync] WARN: $*" >&2; }
err() { echo "[graphify-sync] ERROR: $*" >&2; }

if [[ -z "${GEMINI_API_KEY:-}" && -f "$HOME/.config/graphify/env" ]]; then
  set -a; . "$HOME/.config/graphify/env"; set +a
fi

if [[ -z "${GEMINI_API_KEY:-}" ]]; then
  err "GEMINI_API_KEY not set; aborting"
  exit 1
fi

#----- 1. memory: rsync + rebuild graph
log "memory: rsync auto-memory into workspace"
mkdir -p "$MEMORY_DST"
rsync -a --delete \
  --include='*/' \
  --include='MEMORY.md' \
  --include='memory/' \
  --include='memory/**' \
  --exclude='*' \
  "$SRC_MEMORY" "$MEMORY_DST" || { err "memory rsync failed"; exit 1; }

log "memory: graphify extract"
if ! ( cd "$MEMORY_WS" && graphify extract . --backend gemini ); then
  warn "memory extract failed; continuing"
fi

#----- 2. raw: rebuild personal corpus graph
log "raw: graphify extract"
if ! ( cd "$RAW" && graphify extract . --backend gemini ); then
  warn "raw extract failed; skipping raw push"
  exit 0
fi

#----- 3. raw: per-file semantic commit + push
cd "$RAW"

# Collect changed paths via null-delimited porcelain
mapfile -d '' -t CHANGED < <(git status -z --porcelain | python3 -c '
import sys
buf = sys.stdin.buffer.read()
i = 0
while i < len(buf):
    end = buf.index(b"\0", i)
    entry = buf[i:end].decode("utf-8", "replace")
    i = end + 1
    # Skip "from" name of renames (XY src\0dst\0)
    code = entry[:2]
    path = entry[3:]
    sys.stdout.write(code + "\t" + path + "\0")
    if code[0] == "R":
        # consume src path that follows
        end2 = buf.index(b"\0", i)
        i = end2 + 1
')

if [[ ${#CHANGED[@]} -eq 0 ]]; then
  log "raw: no changes to commit"
  log "done"
  exit 0
fi

log "raw: ${#CHANGED[@]} change(s) to process"

generate_message() {
  local action="$1" path="$2" context="$3"
  local prompt
  case "$action" in
    add)    prompt="Write a Conventional Commits subject line for adding the new file '$path'. Constraints: imperative mood, lowercase, no period, max 60 characters. Use type 'add' (e.g. 'add notes: short summary'). Content preview:\n$context" ;;
    remove) prompt="Write a Conventional Commits subject line for removing the file '$path'. Constraints: imperative, lowercase, no period, max 60 characters. Use type 'remove'." ;;
    *)      prompt="Write a Conventional Commits subject line describing this diff for '$path'. Constraints: imperative, lowercase, no period, max 60 characters. Use 'update' if no clearer type fits. Diff:\n$context" ;;
  esac

  GEMINI_PROMPT="$prompt" python3 <<'PY' 2>/dev/null
import os, sys
from openai import OpenAI
client = OpenAI(
    api_key=os.environ["GEMINI_API_KEY"],
    base_url="https://generativelanguage.googleapis.com/v1beta/openai/",
)
try:
    r = client.chat.completions.create(
        model="gemini-2.0-flash",
        messages=[
            {"role": "system", "content": "You generate concise git commit subject lines. Output the subject line only — no quotes, no markdown, no trailing period. Max 60 chars."},
            {"role": "user", "content": os.environ["GEMINI_PROMPT"]},
        ],
        max_tokens=40,
        temperature=0.2,
    )
    msg = (r.choices[0].message.content or "").strip().strip('"').strip("'").splitlines()[0]
    if not msg:
        sys.exit(2)
    print(msg[:60])
except Exception:
    sys.exit(2)
PY
}

for entry in "${CHANGED[@]}"; do
  [[ -z "$entry" ]] && continue
  code="${entry:0:2}"
  path="${entry#*$'\t'}"

  # Stage the change so we can read it via `git diff --cached`.
  if [[ "$code" == " D" || "$code" == "D " || "$code" == "DD" ]]; then
    action="remove"
    git rm -- "$path" >/dev/null 2>&1 || git add -A -- "$path"
    context=""
  elif [[ "$code" == "??" ]]; then
    action="add"
    git add -- "$path"
    if [[ -f "$path" ]]; then
      context=$(head -c 1500 -- "$path" 2>/dev/null || true)
    else
      context=""
    fi
  else
    action="update"
    git add -- "$path"
    context=$(git diff --cached -- "$path" 2>/dev/null | head -c 2000)
  fi

  msg=$(generate_message "$action" "$path" "$context") || msg=""
  if [[ -z "$msg" ]]; then
    msg="$action: $path"
    warn "LLM message empty for $path; using fallback '$msg'"
  fi

  if git commit -m "$msg" --only -- "$path" >/dev/null 2>&1; then
    log "committed: $msg"
  else
    warn "commit failed for $path; skipping"
  fi
done

#----- 4. push
log "raw: git push"
if git push 2>&1 | sed 's/^/[graphify-sync push] /'; then
  log "done"
else
  warn "git push failed; commits remain local"
fi

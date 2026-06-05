#!/usr/bin/env bash
# graphify-sync: rebuild graphify-memory + graphify-personal graphs, push ~/raw.
# Triggered by graphify-sync.timer (daily) or run manually.
# All LLM work (graph extract + per-file commit messages) routes through the
# locally-installed `claude` CLI (`claude -p`), billed to the Claude Code
# subscription. No API keys required.

set -uo pipefail

SRC_MEMORY="$HOME/.claude/projects/"
MEMORY_WS="$HOME/.graphify/memory-workspace"
MEMORY_DST="$MEMORY_WS/projects/"
RAW="$HOME/raw"
GRAPHIFY_BIN="$HOME/.graphify/venv/bin/graphify"
[[ -x "$GRAPHIFY_BIN" ]] || GRAPHIFY_BIN="graphify"  # fallback to PATH

log() { echo "[graphify-sync] $*"; }
warn() { echo "[graphify-sync] WARN: $*" >&2; }
err() { echo "[graphify-sync] ERROR: $*" >&2; }

if ! command -v claude >/dev/null 2>&1; then
  err "claude CLI not on PATH; required for graph extract and commit messages; aborting"
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

log "memory: regenerate cross-project map (~/.claude/PROJECTS.md)"
"$HOME/dotfiles/scripts/gen-projects-registry.sh" || warn "projects-registry gen failed; continuing"

log "memory: dangling-wikilink check"
SRC_MEMORY_DIR="$SRC_MEMORY" RAW_DIR="$RAW" python3 <<'PY' || warn "wikilink check errored"
import os, re, sys
from pathlib import Path

root = Path(os.environ["SRC_MEMORY_DIR"])
raw = Path(os.environ["RAW_DIR"])
link_re = re.compile(r"\[\[([^\]\|\#]+?)(?:\#[^\]]*)?(?:\|[^\]]*)?\]\]")
name_re = re.compile(r"^name:\s*(.+?)\s*$", re.M)

# Treat raw corpus files (~/raw/**) as valid cross-scope wikilink targets.
global_slugs = set()
if raw.is_dir():
    for f in raw.rglob("*.md"):
        if "graphify-out" in f.parts:
            continue
        global_slugs.add(f.stem)

dangling = []
for project in sorted(p for p in root.iterdir() if p.is_dir()):
    memdir = project / "memory"
    if not memdir.is_dir():
        continue
    md_files = [f for f in memdir.rglob("*.md") if not f.name.endswith(".original.md")]
    slugs = set(global_slugs)
    for f in md_files:
        slugs.add(f.stem)
        try:
            head = f.read_text(errors="ignore")[:800]
        except OSError:
            continue
        m = name_re.search(head)
        if m:
            slugs.add(m.group(1).strip())
    for f in md_files:
        try:
            text = f.read_text(errors="ignore")
        except OSError:
            continue
        for ref in link_re.findall(text):
            ref = ref.strip()
            if ref and ref not in slugs:
                dangling.append((project.name, f.name, ref))

if dangling:
    print(f"[graphify-sync] WARN: {len(dangling)} dangling wikilink(s) found:", file=sys.stderr)
    for proj, src, ref in dangling[:30]:
        print(f"[graphify-sync] WARN:   {proj}/{src} -> [[{ref}]]", file=sys.stderr)
    if len(dangling) > 30:
        print(f"[graphify-sync] WARN:   ... and {len(dangling) - 30} more", file=sys.stderr)
else:
    print("[graphify-sync] wikilinks: all resolved")
PY

log "memory: graphify extract"
( cd "$MEMORY_WS" && "$GRAPHIFY_BIN" extract . --backend claude-cli ) || warn "memory extract failed; continuing"

#----- 1.5. promote: lift generalizable memory entries into ~/raw/from-memory/
# DRY_RUN=1 by default during 7-day burn-in window; flip PROMOTE_DRY_RUN=0 in service env to enable writes.
log "promote: scan memory for promotable entries"
DRY_RUN="${PROMOTE_DRY_RUN:-1}" PROMOTE_MODEL="${PROMOTE_MODEL:-claude-sonnet-4-6}" \
  "$HOME/dotfiles/scripts/promote-memory.sh" || warn "promote-memory failed; continuing"

#----- 2. raw: rebuild personal corpus graph
log "raw: graphify extract"
if ! ( cd "$RAW" && "$GRAPHIFY_BIN" extract . --backend claude-cli ); then
  warn "raw extract failed; will still commit/push file changes"
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

# Commit signing and the push both authenticate through gpg-agent. The daily
# timer fires while the laptop is in use, so a cold cache just pops the normal
# pinentry GUI and the passphrase is typed; a warm 24h cache prompts for
# nothing. With no display up, gpg/ssh error out, the file is skipped, and the
# Persistent timer retries after the next login. No key material lives on disk.

COMMIT_SYS_PROMPT="You generate concise git commit subject lines. Output the subject line only — no quotes, no markdown, no trailing period. Max 60 chars."

generate_message() {
  local action="$1" path="$2" context="$3"
  local prompt msg
  case "$action" in
    add)    prompt="Write a Conventional Commits subject line for adding the new file '$path'. Constraints: imperative mood, lowercase, no period, max 60 characters. Use type 'add' (e.g. 'add notes: short summary'). Content preview:\n$context" ;;
    remove) prompt="Write a Conventional Commits subject line for removing the file '$path'. Constraints: imperative, lowercase, no period, max 60 characters. Use type 'remove'." ;;
    *)      prompt="Write a Conventional Commits subject line describing this diff for '$path'. Constraints: imperative, lowercase, no period, max 60 characters. Use 'update' if no clearer type fits. Diff:\n$context" ;;
  esac

  # claude -p (text-only, single turn, no tool use).
  # Pinned to haiku — short subject-line gen, personal-memory policy disallows opus.
  msg=$(printf '%b' "$prompt" \
    | claude -p --model claude-haiku-4-5-20251001 --max-turns 1 --append-system-prompt "$COMMIT_SYS_PROMPT" 2>/dev/null \
    | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' \
          -e 's/^`//' -e 's/`$//' \
          -e 's/^["'"'"']//' -e 's/["'"'"']$//' \
    | head -n 1)
  if [[ -n "$msg" ]]; then
    echo "${msg:0:60}"
    return 0
  fi

  return 2
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

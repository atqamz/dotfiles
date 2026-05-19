#!/usr/bin/env bash
# promote-memory: lift generalizable entries from per-project memory dirs into ~/raw/from-memory/
# Triggered by graphify-sync.sh (daily) or run manually.
# Env:
#   DRY_RUN=1       -> log candidates to ~/raw/from-memory/.dry-run.log, no writes (default 1 during burn-in)
#   PROMOTE_MODEL   -> Claude model id for feedback classification (default sonnet 4.6)
#
# Model constraint: personal-memory handling uses sonnet or haiku only — never opus.

set -uo pipefail

PROJECTS="$HOME/.claude/projects"
DST="$HOME/raw/from-memory"
MANIFEST="$DST/.promoted-manifest.json"
DRYLOG="$DST/.dry-run.log"
DRY_RUN="${DRY_RUN:-1}"
PROMOTE_MODEL="${PROMOTE_MODEL:-claude-sonnet-4-6}"

log() { echo "[promote-memory] $*"; }
warn() { echo "[promote-memory] WARN: $*" >&2; }

mkdir -p "$DST"
[[ ! -f "$MANIFEST" ]] && echo '{}' > "$MANIFEST"

if ! command -v claude >/dev/null 2>&1; then
  warn "claude CLI not on PATH; aborting"
  exit 1
fi

case "$PROMOTE_MODEL" in
  claude-sonnet-*|claude-haiku-*) ;;
  *) warn "PROMOTE_MODEL=$PROMOTE_MODEL not sonnet/haiku; personal-memory policy disallows opus"; exit 1 ;;
esac

log "scan projects under $PROJECTS (model=$PROMOTE_MODEL dry_run=$DRY_RUN)"

export PROJECTS DST MANIFEST DRYLOG DRY_RUN PROMOTE_MODEL

python3 <<'PY' || { warn "python promote step failed"; exit 1; }
import os, re, json, hashlib, subprocess, datetime, sys
from pathlib import Path

projects = Path(os.environ["PROJECTS"])
dst = Path(os.environ["DST"])
manifest_path = Path(os.environ["MANIFEST"])
drylog = Path(os.environ["DRYLOG"])
dry_run = os.environ["DRY_RUN"] == "1"
model = os.environ["PROMOTE_MODEL"]

manifest = json.loads(manifest_path.read_text() or "{}")

CLASSIFY_PROMPT = (
    "You classify whether a feedback memory entry is generalizable (broadly useful across "
    "projects/situations) or project-specific (narrow to one codebase/task).\n\n"
    "Output exactly one word: GENERALIZABLE or PROJECT_SPECIFIC.\n\n"
    "Generalizable: durable user preferences, communication style, tooling defaults, "
    "philosophies that apply across all work.\n"
    "Project-specific: rules tied to a single repo, codebase quirk, or one-off project state."
)

link_re = re.compile(r"\[\[([^\]\|\#]+?)(?:\#[^\]]*)?(?:\|([^\]]*))?\]\]")
fm_re = re.compile(r"^---\n(.*?)\n---\n?(.*)$", re.S)

def parse_frontmatter(text):
    m = fm_re.match(text)
    if not m:
        return {}, text
    fm_raw, body = m.group(1), m.group(2)
    fm, cur = {}, None
    for line in fm_raw.splitlines():
        if not line.strip():
            continue
        if line.startswith("  ") and cur is not None:
            k, _, v = line.strip().partition(":")
            cur[k.strip()] = v.strip()
        elif line.rstrip().endswith(":"):
            key = line.rstrip().rstrip(":").strip()
            cur = {}
            fm[key] = cur
        else:
            k, _, v = line.partition(":")
            fm[k.strip()] = v.strip()
            cur = None
    return fm, body

def strip_wikilinks(text):
    def repl(m):
        return (m.group(2) or m.group(1)).strip()
    return link_re.sub(repl, text)

def content_hash(text):
    return hashlib.sha256(text.encode()).hexdigest()[:16]

def classify_feedback(content):
    try:
        r = subprocess.run(
            ["claude", "-p", "--model", model, "--max-turns", "1",
             "--append-system-prompt", CLASSIFY_PROMPT],
            input=content[:4000], capture_output=True, text=True, timeout=60,
        )
        out = (r.stdout or "").strip().upper()
        return "GENERALIZABLE" in out
    except Exception as e:
        print(f"[promote-memory] WARN: classify failed ({e}); defaulting to skip", file=sys.stderr)
        return False

def project_slug(p):
    return p.name.lstrip("-")

def safe_filename(s):
    return re.sub(r"[^A-Za-z0-9._-]+", "-", s).strip("-")

candidates = []
for proj in sorted(p for p in projects.iterdir() if p.is_dir()):
    memdir = proj / "memory"
    if not memdir.is_dir():
        continue
    for f in sorted(memdir.rglob("*.md")):
        if f.name == "MEMORY.md" or f.name.endswith(".original.md"):
            continue
        try:
            text = f.read_text(errors="ignore")
        except OSError:
            continue
        fm, body = parse_frontmatter(text)
        # Two frontmatter shapes seen in the wild:
        #  1) nested: metadata: { type: feedback }      (claude code auto-memory)
        #  2) flat:   type: feedback                    (hand-written)
        meta = fm.get("metadata") if isinstance(fm.get("metadata"), dict) else {}
        mem_type = (meta.get("type") or fm.get("type") or "").strip()
        name = (fm.get("name") or f.stem).strip()
        h = content_hash(body)
        key = safe_filename(f"{project_slug(proj)}__{name}")

        prior = manifest.get(key)
        if prior and prior.get("hash") == h:
            continue

        if mem_type == "user":
            decision = "promote"
        elif mem_type == "reference":
            decision = "promote"
        elif mem_type == "feedback":
            decision = "promote" if classify_feedback(body) else "skip-project-specific"
        elif mem_type == "project":
            decision = "skip-project-type"
        else:
            decision = f"skip-type-{mem_type or 'unknown'}"

        candidates.append({
            "key": key, "decision": decision, "fm": fm, "body": body,
            "src": str(f), "hash": h,
        })

ts = datetime.datetime.now().isoformat(timespec="seconds")
today = datetime.date.today().isoformat()

if dry_run:
    with drylog.open("a") as fh:
        fh.write(f"\n=== {ts} (model={model}) ===\n")
        for c in candidates:
            fh.write(f"  {c['decision']:28s}  {c['key']}  (src={c['src']})\n")
    print(f"[promote-memory] DRY_RUN: {len(candidates)} candidates logged to {drylog} (no writes)")
    sys.exit(0)

promoted = skipped = 0
for c in candidates:
    if c["decision"] == "promote":
        out_path = dst / f"{c['key']}.md"
        body = strip_wikilinks(c["body"]).lstrip("\n")
        src_pretty = c["src"].replace(str(Path.home()), "~")
        fm_lines = ["---",
                    f"source: {src_pretty}",
                    f"promoted: {today}",
                    f"name: {c['fm'].get('name', c['key'])}"]
        if c["fm"].get("description"):
            fm_lines.append(f"description: {c['fm']['description']}")
        fm_lines.append("---")
        out_path.write_text("\n".join(fm_lines) + "\n\n" + body)
        promoted += 1
    else:
        skipped += 1
    manifest[c["key"]] = {
        "hash": c["hash"], "decision": c["decision"],
        "checked_at": today, "src": c["src"],
    }

manifest_path.write_text(json.dumps(manifest, indent=2, sort_keys=True))
print(f"[promote-memory] promoted={promoted} skipped={skipped} candidates={len(candidates)}")
PY

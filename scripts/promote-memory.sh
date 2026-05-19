#!/usr/bin/env bash
# promote-memory: lift generalizable entries from per-project memory dirs into ~/raw/from-memory/
# Triggered by graphify-sync.sh (daily) or run manually.
# Env:
#   DRY_RUN=1       -> log candidates to ~/raw/from-memory/.dry-run.log, no writes (default 1 during burn-in)
#   PROMOTE_MODEL   -> Claude model id for classification (default sonnet 4.6)
#
# Model constraint: personal-memory handling uses sonnet or haiku only — never opus.
#
# Classifier (single LLM call per non-project candidate) returns one of:
#   GENERAL          -> promote to ~/raw/from-memory/<key>.md
#   JOB_SCOPED       -> promote to ~/raw/from-memory/jobs/<job>/<key>.md
#                       (job inferred from project dir; if unknown, fallback to root)
#   PROJECT_SPECIFIC -> skip
#   STALE            -> skip (memory references abandoned tools/workflows)

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

CLASSIFY_PROMPT = """You classify a personal-memory entry for promotion to a corpus.

Output exactly ONE of these tokens on the first line, nothing else:

GENERAL          - durable across all work (any job, any project). Tooling defaults,
                   communication style, branch naming conventions, git workflow rules,
                   YAML/TOML conventions, etc.
JOB_SCOPED       - scoped to one job field (yes2games, blankon, or hage) but
                   generalizable within that job. Examples: "use Podman for all blankon
                   repos", "yes2infra is the GitOps repo for all yes2games services",
                   "FOSS-first tooling for blankon".
PROJECT_SPECIFIC - tied to a single codebase, narrow workflow, one-off task, or
                   repo-internal state (e.g., "duel-wager fix uses scripts/foo.py",
                   "feature flag X enabled in repo Y"). Skip.
STALE            - references abandoned tools or workflows the user no longer uses.
                   Stale markers: "gsd", "get-shit-done", "/gsd-*", "phase plans",
                   spec-tracking jargon, deprecated commands. Skip.

Context: project directory is "{project}", inferred job field is "{job}", memory type is "{mtype}"."""

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

def project_slug(p):
    return p.name.lstrip("-")

def safe_filename(s):
    return re.sub(r"[^A-Za-z0-9._-]+", "-", s).strip("-")

# Job-context inference from project dir name.
# Project dirs look like "-home-atqa-repo-<head>-<rest>" where <head> identifies the job.
# Mapping reflects user_job_fields.md:
#   yes2games: repos under ~/repo/yes2games/* and ~/repo/nsr-* (nsr is a yes2games product)
#   blankon:   repos under ~/repo/blankon-*
#   hage:      repos under ~/repo/hage*
JOB_HEAD_MAP = {
    "yes2games": "yes2games",
    "nsr":       "yes2games",
    "blankon":   "blankon",
    "hage":      "hage",
}

def infer_job(slug):
    # slug like "home-atqa-repo-yes2games-internal-workspace-rujak"
    rest = slug.removeprefix("home-atqa-repo-")
    head = rest.split("-", 1)[0]
    return JOB_HEAD_MAP.get(head)

def classify(content, project_slug_str, job, mtype):
    prompt = CLASSIFY_PROMPT.format(project=project_slug_str, job=job or "none", mtype=mtype)
    try:
        r = subprocess.run(
            ["claude", "-p", "--model", model, "--max-turns", "1",
             "--append-system-prompt", prompt],
            input=content[:4000], capture_output=True, text=True, timeout=60,
        )
        out = (r.stdout or "").strip().upper()
        # take first token; tolerate model wrapping
        for token in ("GENERAL", "JOB_SCOPED", "PROJECT_SPECIFIC", "STALE"):
            if token in out:
                return token
        return "PROJECT_SPECIFIC"  # fail closed
    except Exception as e:
        print(f"[promote-memory] WARN: classify failed ({e}); defaulting to skip", file=sys.stderr)
        return "PROJECT_SPECIFIC"

candidates = []
for proj in sorted(p for p in projects.iterdir() if p.is_dir()):
    memdir = proj / "memory"
    if not memdir.is_dir():
        continue
    slug = project_slug(proj)
    job = infer_job(slug)
    for f in sorted(memdir.rglob("*.md")):
        if f.name == "MEMORY.md" or f.name.endswith(".original.md"):
            continue
        try:
            text = f.read_text(errors="ignore")
        except OSError:
            continue
        fm, body = parse_frontmatter(text)
        # Two frontmatter shapes:
        #  1) nested: metadata: { type: feedback }   (claude code auto-memory)
        #  2) flat:   type: feedback                 (hand-written)
        meta = fm.get("metadata") if isinstance(fm.get("metadata"), dict) else {}
        mem_type = (meta.get("type") or fm.get("type") or "").strip()
        name = (fm.get("name") or f.stem).strip()
        h = content_hash(body)
        key = safe_filename(f"{slug}__{name}")

        prior = manifest.get(key)
        if prior and prior.get("hash") == h:
            continue

        # type:project documents project state and is intentionally not promoted.
        if mem_type == "project":
            decision = "skip-type-project"
            classification = None
        # user / feedback / reference all go through the unified classifier.
        elif mem_type in ("user", "feedback", "reference"):
            classification = classify(body, slug, job, mem_type)
            if classification == "GENERAL":
                decision = "promote-general"
            elif classification == "JOB_SCOPED":
                if job:
                    decision = f"promote-job-{job}"
                else:
                    # No job inferable but content claims to be job-scoped.
                    # Fall back to root with a warning marker so reviewer can route manually.
                    decision = "promote-general-fallback"
            elif classification == "STALE":
                decision = "skip-stale"
            else:
                decision = "skip-project-specific"
        else:
            decision = f"skip-type-{mem_type or 'unknown'}"
            classification = None

        candidates.append({
            "key": key, "decision": decision, "classification": classification,
            "fm": fm, "body": body, "src": str(f), "hash": h, "job": job,
        })

ts = datetime.datetime.now().isoformat(timespec="seconds")
today = datetime.date.today().isoformat()

if dry_run:
    with drylog.open("a") as fh:
        fh.write(f"\n=== {ts} (model={model}) ===\n")
        for c in candidates:
            cls = f"[{c['classification']}]" if c['classification'] else ""
            fh.write(f"  {c['decision']:28s} {cls:20s} {c['key']}  (src={c['src']})\n")
    print(f"[promote-memory] DRY_RUN: {len(candidates)} candidates logged to {drylog} (no writes)")
    sys.exit(0)

promoted = skipped = 0
for c in candidates:
    if c["decision"].startswith("promote"):
        if c["decision"].startswith("promote-job-"):
            job = c["decision"].removeprefix("promote-job-")
            out_dir = dst / "jobs" / job
        else:
            out_dir = dst
        out_dir.mkdir(parents=True, exist_ok=True)
        out_path = out_dir / f"{c['key']}.md"
        body = strip_wikilinks(c["body"]).lstrip("\n")
        src_pretty = c["src"].replace(str(Path.home()), "~")
        fm_lines = ["---",
                    f"source: {src_pretty}",
                    f"promoted: {today}",
                    f"promoted_by: auto ({c['classification']})",
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
        "classification": c["classification"],
        "checked_at": today, "src": c["src"],
    }

manifest_path.write_text(json.dumps(manifest, indent=2, sort_keys=True))
print(f"[promote-memory] promoted={promoted} skipped={skipped} candidates={len(candidates)}")
PY

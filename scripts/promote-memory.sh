#!/usr/bin/env bash
# promote-memory: lift generalizable entries from per-project memory dirs into ~/raw/from-memory/
# Triggered by graphify-sync.sh (daily) or run manually.
# Env:
#   DRY_RUN=1       -> generalize + log preview to ~/raw/from-memory/.dry-run.log, no writes (default 1 during burn-in)
#   PROMOTE_MODEL   -> Claude model id for classify + generalize (default sonnet 4.6)
#
# Model constraint: personal-memory handling uses sonnet or haiku only — never opus.
#
# Identity is the TOPIC, not the source path. Filename + manifest key = memory `name`
# (scoped under jobs/<job>/ when job-scoped). A project moving on disk no longer re-dupes.
#
# Two-stage pipeline per non-project candidate:
#   1. classify (LLM)  -> GENERAL | JOB_SCOPED | PROJECT_SPECIFIC | STALE
#   2. generalize (LLM) -> rewrite/redact: strip incidental origin, keep semantic scope.
#        GENERAL    -> project-agnostic principle (strip even job scope)
#        JOB_SCOPED -> keep <job> scope, strip which-repo/session/path origin
#      Sources sharing a topic key are MERGED (union facts) into one generalized note.
#
# Routing:
#   GENERAL          -> ~/raw/from-memory/<name>.md
#   JOB_SCOPED       -> ~/raw/from-memory/jobs/<job>/<name>.md  (root fallback if job unknown)
#   PROJECT_SPECIFIC -> skip
#   STALE            -> skip
#
# Idempotency: manifest v2 keyed by <scope>/<name>, stores per-source input hashes.
# A group regenerates only when its source set or any source body changes.
# Trust the rewrite: no raw original retained for provenance (only a sources: list).
#
# Stale cleanup: corpus files with no current source are removed IF promoted_by: auto.
# Manual files are never auto-deleted — surfaced as orphans for manual reconcile.

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
import os, re, json, hashlib, socket, subprocess, datetime, sys
from pathlib import Path

projects = Path(os.environ["PROJECTS"])
dst = Path(os.environ["DST"])
manifest_path = Path(os.environ["MANIFEST"])
drylog = Path(os.environ["DRYLOG"])
dry_run = os.environ["DRY_RUN"] == "1"
model = os.environ["PROMOTE_MODEL"]
device = socket.gethostname()
home = str(Path.home())

raw_manifest = json.loads(manifest_path.read_text() or "{}")
# v1 manifest (flat slug__name keys) is incompatible with topic-keyed v2 -> rebuild.
manifest = raw_manifest if raw_manifest.get("version") == 2 else {"version": 2, "groups": {}}
gm = manifest.setdefault("groups", {})

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
fence_open_re = re.compile(r"^```[a-zA-Z0-9]*\n")
fence_close_re = re.compile(r"\n```\s*$")

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

def pretty(path_str):
    return path_str.replace(home, "~")

# Job-context inference from project dir name.
# Project dirs look like "-home-atqa-repo-<head>-<rest>" where <head> identifies the job.
JOB_HEAD_MAP = {
    "yes2games": "yes2games",
    "nsr":       "yes2games",
    "blankon":   "blankon",
    "hage":      "hage",
}

def infer_job(slug):
    rest = slug.removeprefix("home-atqa-repo-")
    head = rest.split("-", 1)[0]
    return JOB_HEAD_MAP.get(head)

def classify(content, project_slug_str, job, mtype):
    prompt = CLASSIFY_PROMPT.format(project=project_slug_str, job=job or "none", mtype=mtype)
    try:
        r = subprocess.run(
            ["claude", "-p", "--model", model, "--max-turns", "1", "--tools", "",
             "--append-system-prompt", prompt],
            input=content[:4000], capture_output=True, text=True, timeout=60,
        )
        out = (r.stdout or "").strip().upper()
        for token in ("GENERAL", "JOB_SCOPED", "PROJECT_SPECIFIC", "STALE"):
            if token in out:
                return token
        return "PROJECT_SPECIFIC"  # fail closed
    except Exception as e:
        print(f"[promote-memory] WARN: classify failed ({e}); defaulting to skip", file=sys.stderr)
        return "PROJECT_SPECIFIC"

def generalize(bodies, classification, job):
    """Rewrite/redact one or more topic-sharing bodies into a single corpus note.
    Strip incidental origin; keep semantic scope per classification."""
    if classification == "GENERAL" or not job:
        scope_instr = ("Rewrite it as a project-agnostic principle. Remove ALL traces of "
                       "which specific project, job, repo, workspace, session, file path, "
                       "or one-off task it came from. Keep only the durable fact, rule, or "
                       "preference and its rationale.")
    else:
        scope_instr = (f"Rewrite it scoped to the '{job}' job context. Keep facts, stack, "
                       f"and rules that hold across the {job} job. Remove incidental origin: "
                       "which specific repo, workspace, or session it came from, "
                       "relative-path quirks, and one-off task details.")
    merge_instr = ""
    if len(bodies) > 1:
        merge_instr = (f"The following {len(bodies)} notes (separated by '---') cover the "
                       "same topic. Merge them into ONE coherent note: union the facts, "
                       "dedupe overlaps, resolve conflicts toward the most recent/specific. ")
    sys_prompt = ("You rewrite a personal-memory note for a personal knowledge corpus. "
                  f"{merge_instr}{scope_instr} "
                  "Preserve concrete technical detail (names, URLs, versions, commands). "
                  "Output ONLY the rewritten markdown body — no frontmatter, no code fences "
                  "around the whole thing, no preamble, no sign-off.")
    payload = "\n\n---\n\n".join(b.strip() for b in bodies)
    # The print-mode model flakes nondeterministically (~1/3): sometimes a turn-limit
    # error, sometimes empty output. Retry a few times before giving up.
    for attempt in range(3):
        try:
            r = subprocess.run(
                # tools disabled (pure text transform); generous turn budget so denied
                # tool attempts still leave room to answer. Inputs are small.
                ["claude", "-p", "--model", model, "--max-turns", "8", "--tools", "",
                 "--append-system-prompt", sys_prompt],
                input=payload[:8000], capture_output=True, text=True, timeout=180,
            )
        except Exception as e:
            print(f"[promote-memory] WARN: generalize attempt {attempt+1} raised ({e})", file=sys.stderr)
            continue
        out = (r.stdout or "").strip()
        if r.returncode != 0 or re.match(r"^Error:\s", out) or not out:
            # claude prints control errors (e.g. turn-limit) to stdout with rc=0; empty
            # output is the other flake mode. Both are transient -> retry.
            print(f"[promote-memory] WARN: generalize attempt {attempt+1} no output "
                  f"(rc={r.returncode}): {out[:80]}", file=sys.stderr)
            continue
        out = fence_open_re.sub("", out)
        out = fence_close_re.sub("", out)
        out = out.strip()
        if out:
            return out
    return None

# ----- scan + classify -----
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
        meta = fm.get("metadata") if isinstance(fm.get("metadata"), dict) else {}
        mem_type = (meta.get("type") or fm.get("type") or "").strip()
        name = (fm.get("name") or f.stem).strip()
        h = content_hash(body)

        classification = None
        if mem_type == "project":
            decision = "skip-type-project"
        elif mem_type in ("user", "feedback", "reference"):
            classification = classify(body, slug, job, mem_type)
            if classification == "GENERAL":
                decision = "promote-general"
            elif classification == "JOB_SCOPED":
                decision = f"promote-job-{job}" if job else "promote-general-fallback"
            elif classification == "STALE":
                decision = "skip-stale"
            else:
                decision = "skip-project-specific"
        else:
            decision = f"skip-type-{mem_type or 'unknown'}"

        candidates.append({
            "name": name, "decision": decision, "classification": classification,
            "fm": fm, "body": body, "src": str(f), "hash": h, "job": job,
        })

# ----- group promote candidates by (scope, topic name) -----
def scope_for(decision):
    if decision.startswith("promote-job-"):
        return "jobs/" + decision.removeprefix("promote-job-")
    return ""  # general or general-fallback -> corpus root

groups = {}  # gkey -> {scope, key, classification, job, members[]}
for c in candidates:
    if not c["decision"].startswith("promote"):
        continue
    scope = scope_for(c["decision"])
    key = safe_filename(c["name"])
    gkey = f"{scope}/{key}" if scope else key
    g = groups.setdefault(gkey, {
        "scope": scope, "key": key,
        "classification": c["classification"], "job": c["job"], "members": [],
    })
    g["members"].append(c)

ts = datetime.datetime.now().isoformat(timespec="seconds")
today = datetime.date.today().isoformat()

def group_inputs(g):
    return {pretty(m["src"]): m["hash"] for m in g["members"]}

def out_path_for(g):
    out_dir = dst / g["scope"] if g["scope"] else dst
    return out_dir / f"{g['key']}.md"

skips = [c for c in candidates if not c["decision"].startswith("promote")]

# ----- dry-run: generalize + preview, no writes -----
if dry_run:
    with drylog.open("a") as fh:
        fh.write(f"\n=== {ts} (model={model}) ===\n")
        fh.write(f"-- {len(groups)} promote groups, {len(skips)} skips --\n")
        for gkey, g in sorted(groups.items()):
            prior = gm.get(gkey)
            inputs = group_inputs(g)
            op = out_path_for(g)
            unchanged = bool(prior and prior.get("inputs") == inputs and op.exists())
            srcs = ", ".join(sorted(inputs))
            tag = "UNCHANGED" if unchanged else ("MERGE" if len(g["members"]) > 1 else "NEW")
            fh.write(f"\n[{tag}] {pretty(str(op))}  ({g['classification']})\n")
            fh.write(f"   sources: {srcs}\n")
            if not unchanged:
                new_body = generalize([strip_wikilinks(m["body"]) for m in g["members"]],
                                      g["classification"], g["job"])
                preview = (new_body or "(generalize failed)")
                fh.write("   --- generalized preview ---\n")
                fh.write("\n".join("   " + ln for ln in preview.splitlines()) + "\n")
        # orphan survey (no deletion in dry-run)
        current = {out_path_for(g).resolve() for g in groups.values()}
        for f in sorted(dst.rglob("*.md")):
            if f.name.startswith(".") or f.resolve() in current:
                continue
            pfm, _ = parse_frontmatter(f.read_text(errors="ignore"))
            pb = (pfm.get("promoted_by") or "").strip()
            kind = "auto-orphan WOULD-DELETE" if pb.startswith("auto") else "MANUAL-ORPHAN review"
            fh.write(f"\n[{kind}] {pretty(str(f))}  (promoted_by: {pb or 'unset'})\n")
        for c in skips:
            cls = f"[{c['classification']}]" if c["classification"] else ""
            fh.write(f"  {c['decision']:28s} {cls:14s} {pretty(c['src'])}\n")
    print(f"[promote-memory] DRY_RUN: {len(groups)} groups, {len(skips)} skips -> preview in {drylog} (no writes)")
    sys.exit(0)

# ----- live: generalize/merge, write, prune -----
promoted = skipped = failed = 0
current_files = set()
for gkey, g in sorted(groups.items()):
    op = out_path_for(g)
    current_files.add(op.resolve())
    inputs = group_inputs(g)
    prior = gm.get(gkey)
    if prior and prior.get("inputs") == inputs and op.exists():
        skipped += 1
        continue  # idempotent: source set + bodies unchanged
    new_body = generalize([strip_wikilinks(m["body"]) for m in g["members"]],
                          g["classification"], g["job"])
    if not new_body:
        print(f"[promote-memory] WARN: skip {gkey}; generalize produced nothing", file=sys.stderr)
        failed += 1
        gm[gkey] = prior or {}
        continue
    op.parent.mkdir(parents=True, exist_ok=True)
    desc = next((m["fm"].get("description") for m in g["members"] if m["fm"].get("description")), "")
    srcs = sorted(pretty(m["src"]) for m in g["members"])
    fm_lines = ["---", "sources:"]
    fm_lines += [f"  - {s}" for s in srcs]
    fm_lines += [f"promoted: {today}",
                 f"promoted_by: auto ({g['classification']})",
                 f"promoted_from: {device}",
                 f"name: {g['key']}"]
    if desc:
        fm_lines.append(f"description: {desc}")
    fm_lines.append("---")
    op.write_text("\n".join(fm_lines) + "\n\n" + new_body.lstrip("\n") + "\n")
    gm[gkey] = {
        "inputs": inputs, "output_hash": content_hash(new_body),
        "classification": g["classification"], "scope": g["scope"],
        "checked_at": today, "device": device,
    }
    promoted += 1

# prune manifest groups whose topic no longer has any source
for gk in list(gm):
    if gk not in groups:
        gm.pop(gk, None)

# stale cleanup: auto-promoted corpus files with no current source -> remove; manual -> report
removed_auto, manual_orphans = [], []
for f in sorted(dst.rglob("*.md")):
    if f.name.startswith(".") or f.resolve() in current_files:
        continue
    pfm, _ = parse_frontmatter(f.read_text(errors="ignore"))
    pb = (pfm.get("promoted_by") or "").strip()
    if pb.startswith("auto"):
        f.unlink()
        removed_auto.append(pretty(str(f)))
    else:
        manual_orphans.append(pretty(str(f)))

manifest_path.write_text(json.dumps(manifest, indent=2, sort_keys=True))
print(f"[promote-memory] promoted={promoted} unchanged={skipped} failed={failed} "
      f"groups={len(groups)} removed_auto_orphans={len(removed_auto)}")
for p in removed_auto:
    print(f"[promote-memory]   removed auto-orphan: {p}")
for p in manual_orphans:
    print(f"[promote-memory]   WARN manual-orphan (review/reconcile): {p}", file=sys.stderr)
PY

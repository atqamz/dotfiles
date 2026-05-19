#!/usr/bin/env bash
# memory-stale-report: scan ~/.claude/projects/*/memory/ for likely-stale auto-memories,
# write a markdown report to ~/.graphify/memory-stale-report.md.
# Triggered weekly by memory-stale-report.timer. Non-destructive (report only).

set -uo pipefail

SRC="$HOME/.claude/projects"
OUT="$HOME/.graphify/memory-stale-report.md"

log() { echo "[memory-stale-report] $*"; }
warn() { echo "[memory-stale-report] WARN: $*" >&2; }
err() { echo "[memory-stale-report] ERROR: $*" >&2; }

if [[ -z "${GEMINI_API_KEY:-}" ]] && command -v pass >/dev/null 2>&1; then
  GEMINI_API_KEY="$(pass show dotfiles/api-key/gemini 2>/dev/null || true)"
  [[ -n "$GEMINI_API_KEY" ]] && export GEMINI_API_KEY
fi

HAS_GEMINI=0; HAS_CLAUDE=0
[[ -n "${GEMINI_API_KEY:-}" ]] && HAS_GEMINI=1
command -v claude >/dev/null 2>&1 && HAS_CLAUDE=1

if [[ $HAS_GEMINI -eq 0 && $HAS_CLAUDE -eq 0 ]]; then
  err "no LLM available (need GEMINI_API_KEY via pass, or claude CLI on PATH); aborting"
  exit 1
fi
[[ $HAS_GEMINI -eq 0 ]] && warn "GEMINI_API_KEY unavailable; using claude -p only"
[[ $HAS_CLAUDE -eq 0 ]] && warn "claude CLI not on PATH; gemini only (no fallback)"

export HAS_GEMINI HAS_CLAUDE

mkdir -p "$(dirname "$OUT")"

log "scanning memory dirs under $SRC"

SRC_MEMORY_DIR="$SRC" OUTPUT_PATH="$OUT" python3 <<'PY' || { err "report generation failed"; exit 1; }
import os, sys, json, time, re, subprocess
from pathlib import Path

HAS_GEMINI = os.environ.get("HAS_GEMINI") == "1"
HAS_CLAUDE = os.environ.get("HAS_CLAUDE") == "1"

if HAS_GEMINI:
    from openai import OpenAI

root = Path(os.environ["SRC_MEMORY_DIR"])
out_path = Path(os.environ["OUTPUT_PATH"])
now = time.time()

candidates = []
all_count = 0
stale_keywords = re.compile(r"\b(current|sprint|wip|in[- ]progress|active|today|tomorrow|this week|this month|q[1-4])\b", re.I)

for project in sorted(p for p in root.iterdir() if p.is_dir()):
    memdir = project / "memory"
    if not memdir.is_dir():
        continue
    for f in sorted(memdir.rglob("*.md")):
        if f.name == "MEMORY.md":
            continue
        if f.name.endswith(".original.md"):
            continue  # caveman-compress backups, not active memory
        all_count += 1
        try:
            text = f.read_text(errors="ignore")
        except OSError:
            continue
        mtime = f.stat().st_mtime
        age_days = (now - mtime) / 86400
        keyword_hit = bool(stale_keywords.search(text[:2000]))
        if age_days >= 90 or keyword_hit:
            candidates.append({
                "project": project.name,
                "path": str(f.relative_to(root)),
                "age_days": round(age_days, 1),
                "keyword_hit": keyword_hit,
                "preview": text[:1200],
            })

if not candidates:
    out_path.write_text(
        f"# Memory stale report\n\nGenerated: {time.strftime('%Y-%m-%d %H:%M:%S %z')}\n\n"
        f"Scanned {all_count} memory file(s). No stale candidates flagged (age < 90d, no stale keywords).\n"
    )
    print(f"[memory-stale-report] scanned {all_count}, 0 candidates; wrote {out_path}")
    sys.exit(0)

# Trim previews to keep prompt small.
for c in candidates:
    c["preview"] = c["preview"][:600]

SYS_PROMPT = "Output ONLY valid JSON. No prose, no markdown fences."
prompt = (
    "You are reviewing Claude Code auto-memory files for staleness. For each candidate below, "
    "decide if the memory looks stale (outdated, completed-project, deadline-passed, contradicted-by-newer-info) "
    "or still useful. Return STRICT JSON: a list of objects with keys "
    '"path" (string), "verdict" ("stale" | "fresh" | "unsure"), "reason" (short, <=120 chars). '
    "Do not output anything except the JSON. Today is "
    + time.strftime("%Y-%m-%d") + ".\n\n"
    "Candidates:\n" + json.dumps(candidates, ensure_ascii=False, indent=2)
)

def parse_json_list(raw_text):
    raw_text = re.sub(r"^```(?:json)?\s*|\s*```$", "", raw_text.strip(), flags=re.M).strip()
    parsed = json.loads(raw_text)
    if not isinstance(parsed, list):
        raise ValueError("LLM did not return a list")
    return parsed

def call_gemini():
    client = OpenAI(
        api_key=os.environ["GEMINI_API_KEY"],
        base_url="https://generativelanguage.googleapis.com/v1beta/openai/",
    )
    r = client.chat.completions.create(
        model="gemini-2.0-flash",
        messages=[
            {"role": "system", "content": SYS_PROMPT},
            {"role": "user", "content": prompt},
        ],
        max_tokens=2048,
        temperature=0.1,
    )
    return parse_json_list(r.choices[0].message.content or "")

def call_claude():
    result = subprocess.run(
        ["claude", "-p", "--max-turns", "1",
         "--append-system-prompt", SYS_PROMPT],
        input=prompt, capture_output=True, text=True, timeout=300,
    )
    if result.returncode != 0:
        raise RuntimeError(f"claude -p exited {result.returncode}: {result.stderr[:200]}")
    return parse_json_list(result.stdout)

verdicts = None
provider = None
errors = []

if HAS_GEMINI:
    try:
        verdicts = call_gemini()
        provider = "gemini-2.0-flash"
    except Exception as e:
        errors.append(f"gemini: {e}")
        print(f"[memory-stale-report] gemini failed: {e}; trying claude -p", file=sys.stderr)

if verdicts is None and HAS_CLAUDE:
    try:
        verdicts = call_claude()
        provider = "claude -p"
    except Exception as e:
        errors.append(f"claude: {e}")

if verdicts is None:
    err_summary = "; ".join(errors) if errors else "no LLM provider available"
    out_path.write_text(
        f"# Memory stale report\n\nGenerated: {time.strftime('%Y-%m-%d %H:%M:%S %z')}\n\n"
        f"LLM call(s) failed: {err_summary}\n\nHeuristic candidates ({len(candidates)} flagged by age/keyword):\n\n"
        + "\n".join(f"- `{c['path']}` (age {c['age_days']}d, kw={c['keyword_hit']})" for c in candidates)
    )
    print(f"[memory-stale-report] all LLMs failed ({err_summary}); wrote heuristic-only report")
    sys.exit(0)

by_path = {v.get("path"): v for v in verdicts if isinstance(v, dict)}

stale = []
unsure = []
fresh = []
for c in candidates:
    v = by_path.get(c["path"], {})
    verdict = v.get("verdict", "unsure")
    reason = v.get("reason", "(no reason given)")
    row = (c["path"], c["age_days"], c["keyword_hit"], reason)
    if verdict == "stale":
        stale.append(row)
    elif verdict == "fresh":
        fresh.append(row)
    else:
        unsure.append(row)

def fmt(rows):
    if not rows:
        return "_(none)_\n"
    out = []
    for path, age, kw, reason in rows:
        out.append(f"- `{path}` (age {age}d, keyword_hit={kw}) — {reason}")
    return "\n".join(out) + "\n"

report = [
    "# Memory stale report",
    "",
    f"Generated: {time.strftime('%Y-%m-%d %H:%M:%S %z')}",
    f"Provider: {provider}.",
    f"Scanned: {all_count} file(s). Flagged candidates: {len(candidates)}.",
    "",
    "## Stale (review and prune/update)",
    "",
    fmt(stale),
    "## Unsure (manual eyeball)",
    "",
    fmt(unsure),
    "## Fresh-after-review (LLM said still useful)",
    "",
    fmt(fresh),
]
out_path.write_text("\n".join(report))
print(
    f"[memory-stale-report] scanned {all_count}, "
    f"{len(candidates)} flagged, {len(stale)} stale, "
    f"{len(unsure)} unsure, {len(fresh)} fresh; wrote {out_path}"
)
PY

log "done"

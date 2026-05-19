# Git

- No `Co-Authored-By` lines.
- Trunk-based. New branch from default. No direct commits to `master`/`main` unless asked.
- Branches: `<issue#>-<slug>` (`42-fix-auth-timeout`). No issue → descriptive slug.
- One logical change per commit. Imperative, lowercase start, no trailing period. Body optional.
- No planning jargon: no "phase", "step", "milestone", "part X of Y", "stage", spec-tracking, task IDs (`02-01`, `phase-3`). Describe what commit does, not where it fits.
- GPG signing always on. Never `--no-gpg-sign`, `-c commit.gpgsign=false`.
- Never `--no-verify`.
- Never force-push to default branch.
- Merge via PR when on GitHub. No local merges.
- Don't push or create PRs unless asked.

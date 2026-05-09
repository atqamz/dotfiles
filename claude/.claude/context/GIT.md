# Git Workflow

- **No Co-Authored-By:** Never add `Co-Authored-By` lines to commit messages.
- **Trunk-based development:** New branch from default always. No direct commits to `master` or `main`. Except if asked.
- **Branch naming:** `<issue-number>-<short-description>` (e.g. `42-fix-auth-timeout`). No issue → descriptive slug.
- **Focused commits:** One logical change. Imperative mood, lowercase start, no trailing period. Body optional.
- **No planning jargon in commits:** No "phase", "step", "milestone", "part X of Y", "stage", spec-tracking language. No phase numbers, plan numbers, task IDs (e.g. `02-01`, `phase-3`, `01-02`) in messages or scopes. Describe what commit does, not where it fits.
- **GPG signing:** All commits/tags signed via gitconfig. Never pass `--no-gpg-sign` or `-c commit.gpgsign=false`.
- **Never skip hooks:** No `--no-verify`.
- **Never force-push to default branch.**
- **Merge via PR:** No local merges when project on GitHub. All merges through pull requests.
- **Don't push or create PRs unless asked.**
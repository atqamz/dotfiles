# Git Workflow

- **No Co-Authored-By:** Never add `Co-Authored-By` lines to commit messages.
- **Trunk-based development:** Always create a new branch from the default
  branch. Never commit directly to `master` or `main`.
- **Branch naming:** `<issue-number>-<short-description>` (e.g.
  `42-fix-auth-timeout`). If no issue, use a descriptive slug.
- **Worktrees:** When starting a new task, create a worktree for isolation.
- **Focused commits:** One logical change per commit. Imperative mood, lowercase
  start, no trailing period. Body optional.
- **GPG signing:** All commits/tags are signed via gitconfig. Never pass
  `--no-gpg-sign` or `-c commit.gpgsign=false`.
- **Never skip hooks:** No `--no-verify`.
- **Never force-push to default branch.**
- **Merge via PR:** Do not merge branches locally when the project is on GitHub.
  All merges go through pull requests.
- **Don't push or create PRs unless asked.**

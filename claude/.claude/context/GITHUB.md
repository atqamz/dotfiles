# GitHub

- **Always use `gh` CLI** for all GitHub ops (PRs, issues, checks, releases, API). No raw `curl` or web UI.
- **PR creation:** Push with `-u`, then `gh pr create`. Title < 70 chars. Body: `## Summary` (1-3 bullets), `Fixes #N` if applicable, `## Test plan`.
- **Cross-repo references:** Use `<org>/<repo>#<number>` format.
- **PR inspection:** `gh pr view`, `gh pr checks`, `gh pr diff`.
- **Issues:** `gh issue view`, `gh issue list`, `gh issue create`.
- **Alias available:** `gh co <number>` = `gh pr checkout`.
- **Assignee:** Always assign `atqamz` on every PR/issue (`--assignee atqamz`).
- **Merge strategy:** Normal merge only (`gh pr merge --merge`). No squash/rebase.
- **No planning jargon in issues/PRs:** No "phase", "milestone", "step", "stage", or spec-tracking language in titles/bodies. Describe work done.
- **Post-merge cleanup:** After `gh pr merge`, delete remote branch (`gh pr merge --delete-branch` or `git push origin --delete <branch>`), remove local worktree (`git worktree remove <path>`), delete local branch (`git branch -d <branch>`).
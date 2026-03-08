# GitHub

- **Always use `gh` CLI** for all GitHub operations (PRs, issues, checks,
  releases, API). Never raw `curl` or web UI.
- **PR creation:** Push with `-u`, then `gh pr create`. Title < 70 chars.
  Body: `## Summary` (1-3 bullets), `Fixes #N` if applicable, `## Test plan`.
- **Cross-repo references:** Use `<org>/<repo>#<number>` format.
- **PR inspection:** `gh pr view`, `gh pr checks`, `gh pr diff`.
- **Issues:** `gh issue view`, `gh issue list`, `gh issue create`.
- **Alias available:** `gh co <number>` = `gh pr checkout`.
- **Assignee:** Always assign `atqamz` on every PR and issue we create
  (`--assignee atqamz`).
- **Don't create PRs or push unless explicitly asked.**
- **Merge strategy:** Always use normal merge (`gh pr merge --merge`), never
  squash or rebase.
- **Post-merge cleanup:** After `gh pr merge`, always delete the remote branch
  (`gh pr merge --delete-branch` or `git push origin --delete <branch>`), remove
  the local worktree (`git worktree remove <path>`), and delete the local branch
  (`git branch -d <branch>`).

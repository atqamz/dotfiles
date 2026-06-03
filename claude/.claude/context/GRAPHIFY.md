# graphify

- `~/.claude/skills/graphify/SKILL.md` — input → knowledge graph. `/graphify` → Skill tool `skill:"graphify"`.

# graphify MCP

- **graphify-personal** — graph over `~/raw/`. `mcp__graphify-personal__*`: "what do I know about X", "X relates to Y".
- **graphify-memory** — graph over `~/.graphify/memory-workspace/projects/` (rsync of `~/.claude/projects/*/memory/`). `mcp__graphify-memory__*`: cross-session/cross-project recall.
- **Auto-sync** — systemd user timer `graphify-sync.timer` → `~/dotfiles/scripts/graphify-sync.sh` daily (Persistent). Rebuilds both, pushes `~/raw`→`atqamz/raw`. All LLM work (graph extract `--backend claude-cli` + per-file commit messages) via `claude -p` on the Claude Code subscription — no API keys. Manual: `systemctl --user start graphify-sync.service`. Log: `journalctl --user -u graphify-sync.service -f`.

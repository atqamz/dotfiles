# Global Context

Defaults. Project CLAUDE.md overrides.

@context/GIT.md
@context/GITHUB.md
@context/CODING.md
@context/COMMUNICATION.md
@context/SECURITY.md

# graphify
- `~/.claude/skills/graphify/SKILL.md` — input → knowledge graph. Trigger `/graphify` → Skill tool, `skill: "graphify"`.

# graphify MCP
- **graphify-personal** — graph over `~/raw/`. `mcp__graphify-personal__*` for "what do I know about X", "X relates to Y in notes".
- **graphify-memory** — graph over `~/.graphify/memory-workspace/projects/` (rsync `~/.claude/projects/*/memory/`). `mcp__graphify-memory__*` for cross-session, cross-project recall.
- **Auto-rebuild + push** — systemd user timer `graphify-sync.timer` runs `~/dotfiles/scripts/graphify-sync.sh` daily (Persistent=true). Rebuilds both, pushes `~/raw` → `atqamz/raw` with Gemini per-file commits (fallback `claude -p`). Manual `systemctl --user start graphify-sync.service`. Log `journalctl --user -u graphify-sync.service -f`. `GEMINI_API_KEY` from `pass show dotfiles/api-key/gemini` (gpg agent unlocked).
